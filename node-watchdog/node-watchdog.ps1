#Requires -Version 5.1
# node-watchdog.ps1 - Globaler Watchdog fuer node.exe/electron.exe/esbuild.exe.
#
# Prueft systemweit Zielprozesse gegen drei belegbare Kill-Kriterien:
#   1. Orphan      - Eltern-PID existiert nicht mehr (PID-Reuse-Schutz: Eltern-
#                    Startzeit muss aelter sein als die des Kindes).
#   2. Idle-Aged   - Alter > MaxAgeHours UND Lebenszeit-CPU < IdleCpuSeconds.
#   reasons muessen belegt sein, es gibt keinen "Verdacht"-Kill.
#   3. Stale Port  - lauscht auf einem ueberwachten Dev-Port und ist aelter als
#                    PortStaleHours.
#
# Sicherheit: DryRun ist Default (-Apply zum tatsaechlichen Killen), Report mit
# PID/Name/Alter/CPU/Ports/Grund/Eltern-Status, Whitelist per Substring-Match
# gegen die CommandLine (Datei whitelist.txt, Override -IncludeWhitelisted),
# Selbstschutz (eigene PID + Elternkette werden nie beendet), Prozessbaum-Kill
# via taskkill /T /F, Log mit Rotation (>5 MB), Exit 1 bei Fehlern.
#
# Benutzung:
#   pwsh -File node-watchdog.ps1                    # DryRun-Report
#   pwsh -File node-watchdog.ps1 -Apply             # Kill inkl. Prozessbaum
#   pwsh -File node-watchdog.ps1 -PortStaleHours 0  # Port-Test
#   pwsh -File node-watchdog.ps1 -MaxAgeHours 0 -IdleCpuSeconds 0 -Apply

param(
	[switch]$Apply,
	[double]$MaxAgeHours = 8,
	[double]$IdleCpuSeconds = 120,
	[double]$PortStaleHours = 24,
	[string[]]$WatchedPorts = @('3131', '3132', '5173', '5174', '3000', '8080'),
	[string]$WhitelistPath,
	[string]$LogPath,
	[switch]$IncludeWhitelisted,
	[switch]$Quiet
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# ---------------------------------------------------------------- Konfiguration
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $LogPath) { $LogPath = Join-Path $scriptDir 'node-watchdog.log' }
if (-not $WhitelistPath) { $WhitelistPath = Join-Path $scriptDir 'whitelist.txt' }
$MaxLogBytes = 5MB
$LogArchivesToKeep = 3
$killFailures = 0
$eligibleCount = 0

function Write-Log {
	param([string]$Message)
	$line = '{0} {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
	if (-not $Quiet) { Write-Host $line }
	$dir = Split-Path -Parent $LogPath
	if ($dir -and -not (Test-Path $dir)) {
		New-Item -ItemType Directory -Force -Path $dir | Out-Null
	}
	if (Test-Path $LogPath) {
		if ((Get-Item $LogPath).Length -gt $MaxLogBytes) {
			# Rotation: node-watchdog.log -> .1 -> .2 -> .3 (aeltere fallen weg)
			for ($i = $LogArchivesToKeep; $i -ge 1; $i--) {
				$src = if ($i -eq 1) { $LogPath } else { "$LogPath.$($i - 1)" }
				$dst = "$LogPath.$i"
				if (Test-Path $src) {
					if ($i -eq $LogArchivesToKeep -and (Test-Path $dst)) {
						Remove-Item -Path $dst -Force
					}
					Move-Item -Path $src -Destination $dst -Force
				}
			}
		}
	}
	Add-Content -Path $LogPath -Value $line -Encoding UTF8
}

# ---------------------------------------------------------------- Whitelist
$whitelistPatterns = @()
if (Test-Path $WhitelistPath) {
	foreach ($line in Get-Content -Path $WhitelistPath -ErrorAction SilentlyContinue) {
		$t = $line.Trim()
		if ($t -and -not $t.StartsWith('#')) { $whitelistPatterns += $t.ToLowerInvariant() }
	}
}
Write-Log ("Start: Mode={0} MaxAgeHours={1} IdleCpuSeconds={2} PortStaleHours={3} Ports={4} WhitelistMuster={5}" -f $(if ($Apply) { 'APPLY' } else { 'DRYRUN' }), $MaxAgeHours, $IdleCpuSeconds, $PortStaleHours, ($WatchedPorts -join ','), $whitelistPatterns.Count)

function Test-Whitelisted {
	param([string]$CommandLine, [string]$ExecutablePath)
	$path = $ExecutablePath
	if (-not $path) { $path = '' }
	$haystack = ('{0} {1}' -f $path, $CommandLine).ToLowerInvariant()
	foreach ($pattern in $whitelistPatterns) {
		if ($haystack.Contains($pattern)) { return $true }
	}
	return $false
}

# ---------------------------------------------------------------- Selbstschutz
# Eigene PID + komplette Elternkette: nie Kandidaten.
$protectedPids = @{}
$currentPid = $PID
while ($currentPid) {
	$protectedPids[[int]$currentPid] = $true
	$proc = Get-CimInstance Win32_Process -Filter "ProcessId = $currentPid" -ErrorAction SilentlyContinue
	if ($proc -and $proc.ParentProcessId) {
		$currentPid = [int]$proc.ParentProcessId
	} else {
		break
	}
}
Write-Log ("Selbstschutz: {0} geschuetzte PIDs (eigene Kette)." -f $protectedPids.Count)

# ---------------------------------------------------------------- Datenbasis
$now = Get-Date
$allProcesses = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue
$byPid = @{}
foreach ($p in $allProcesses) { $byPid[[int]$p.ProcessId] = $p }

# Port-Besitzer aus Get-NetTCPConnection lesen (locale-unabhaengig; der
# netstat-Ansatz scheiterte auf nicht-englischen Windows-UIs, weil der Parser
# 'LISTENING' erwartet, dort aber z. B. 'ABHOeREN' steht - ADR-001/H2).
$portOwners = @{}   # "port" -> HashSet von PIDs
try {
	$listenConns = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue
	foreach ($conn in $listenConns) {
		$localPort = [string]$conn.LocalPort
		$ownerPid = [int]$conn.OwningProcess
		if (-not $portOwners.ContainsKey($localPort)) {
			$portOwners[$localPort] = New-Object 'System.Collections.Generic.HashSet[int]'
		}
		$null = $portOwners[$localPort].Add($ownerPid)
	}
} catch {
	Write-Log ("WARN Port-Mapping fehlgeschlagen: {0}" -f $_)
}

# ---------------------------------------------------------------- Bewertung
$eligible = New-Object 'System.Collections.Generic.List[object]'
foreach ($proc in $allProcesses) {
	$name = [string]$proc.Name
	if ($name -notin @('node.exe', 'electron.exe', 'esbuild.exe')) { continue }

	$pidInt = [int]$proc.ProcessId
	if ($protectedPids.ContainsKey($pidInt)) { continue }

	# CommandLine lesen; nicht lesbar -> ueberspringen, markieren
	$cmdline = $proc.CommandLine
	if (-not $cmdline) {
		Write-Log ("SKIP PID {0} ({1}): CommandLine nicht lesbar." -f $pidInt, $name)
		continue
	}

	$isWhitelisted = Test-Whitelisted -CommandLine $cmdline -ExecutablePath $proc.ExecutablePath
	if ($isWhitelisted -and -not $IncludeWhitelisted) { continue }

	# Elternstatus mit PID-Reuse-Schutz
	$parentPid = [int]$proc.ParentProcessId
	$parentStatus = 'unbekannt'
	$isOrphan = $false
	$parentObj = $null
	if ($byPid.ContainsKey($parentPid)) { $parentObj = $byPid[$parentPid] }
	if (-not $parentObj) {
		$parentStatus = 'tot'
		$isOrphan = $true
	} else {
		try {
			$parentCreated = $parentObj.CreationDate
			$childCreated = $proc.CreationDate
			if ($parentCreated -and $childCreated -and ($parentCreated -gt $childCreated)) {
				# Eltern-Startzeit JUENGER als Kind -> PID-Reuse, urspruenglicher
				# Elternteil tot. (Vorher invertiert: parentCreated < childCreated
				# ist der Normalfall jeder Eltern-Kind-Beziehung und flaggte
				# Prozesse mit lebendem Elternteil als verwaist - ADR-001/H6.)
				$parentStatus = 'PID-Reuse (verwaist)'
				$isOrphan = $true
			} else {
				$parentStatus = 'lebt'
			}
		} catch {
			$parentStatus = 'unbekannt'
		}
	}

	# Alter + CPU
	# Volle Praezision fuer Kriterien (Runden wuerde -PortStaleHours 0 killen),
	# gerundet nur fuer den Report.
	$ageHoursRaw = 0.0
	$ageHours = 0.0
	if ($proc.CreationDate) {
		$ageHoursRaw = ($now - $proc.CreationDate).TotalHours
		$ageHours = [math]::Round($ageHoursRaw, 2)
	}
	$cpuSeconds = 0.0
	try {
		$psObj = Get-Process -Id $pidInt -ErrorAction SilentlyContinue
		if ($psObj -and $psObj.TotalProcessorTime) { $cpuSeconds = [math]::Round($psObj.TotalProcessorTime.TotalSeconds, 1) }
	} catch { $cpuSeconds = 0.0 }

	# Ports des Prozesses
	$ownedPorts = @()
	foreach ($portEntry in $portOwners.GetEnumerator()) {
		if ($portEntry.Value.Contains($pidInt)) { $ownedPorts += $portEntry.Key }
	}

	# Kill-Kriterien (nur belegbare Leftovers)
	$reasons = @()
	if ($isOrphan) { $reasons += 'orphan' }
	if ($ageHoursRaw -gt $MaxAgeHours -and $cpuSeconds -lt $IdleCpuSeconds) { $reasons += 'idle-aged' }
	$stalePortHit = $false
	foreach ($wp in $WatchedPorts) {
		if ($ownedPorts -contains $wp -and $ageHoursRaw -gt $PortStaleHours) {
			$stalePortHit = $true
			break
		}
	}
	if ($stalePortHit) { $reasons += 'stale-port' }

	if ($reasons.Count -gt 0) {
		$eligibleCount++
		$eligible.Add([PSCustomObject]@{
			Pid = $pidInt
			Name = $name
			AgeHours = $ageHours
			CpuSeconds = $cpuSeconds
			Ports = ($ownedPorts -join ',')
			Reasons = ($reasons -join '+')
			ParentStatus = $parentStatus
			Whitelisted = $isWhitelisted
			CommandLine = $cmdline
		})
	}
}

# ---------------------------------------------------------------- Report
Write-Log ("Bewertet: {0} Zielprozesse, {1} Kandidaten." -f $allProcesses.Count, $eligibleCount)
if ($eligible.Count -gt 0) {
	foreach ($c in $eligible) {
		Write-Log ("KANDIDAT PID {0} ({1}) Alter={2}h CPU={3}s Ports=[{4}] Grund={5} Eltern={6}{7}" -f $c.Pid, $c.Name, $c.AgeHours, $c.CpuSeconds, $c.Ports, $c.Reasons, $c.ParentStatus, $(if ($c.Whitelisted) { ' [WHITELISTED-override]' } else { '' }))
	}

}

# ---------------------------------------------------------------- Kill / DryRun
if (-not $Apply) {
	Write-Log 'DRYRUN: kein Kill (-Apply fuer tatsaechliches Beenden).'
	exit 0
}

foreach ($c in $eligible) {
	Write-Log ("KILL PID {0} ({1}) Grund={2} inkl. Prozessbaum." -f $c.Pid, $c.Name, $c.Reasons)
	& taskkill.exe /PID $c.Pid /T /F 2>$null
	if ($LASTEXITCODE -ne 0) {
		$killFailures++
		Write-Log ("WARN taskkill fuer PID {0} fehlgeschlagen (Exit {1})." -f $c.Pid, $LASTEXITCODE)
	}
}

if ($killFailures -gt 0) {
	Write-Log ("Fertig: {0} Kill-Fehler." -f $killFailures)
	exit 1
}
Write-Log 'Fertig: alle Kandidaten beendet.'
exit 0
