#Requires -Version 5.1
# 99-selbstpruefung.ps1 - READ-ONLY Pruefung des Fenster-Flash-Audits.
# Fuehrt nur Abfragen aus (Get-ScheduledTask, Datei-Lesezugriffe).
# Veraendert nichts: keine Registrierung, kein Kill, kein Schreibzugriff.
# Aufruf: powershell -NoProfile -ExecutionPolicy Bypass -File 99-selbstpruefung.ps1

$ErrorActionPreference = 'Continue'
Set-StrictMode -Version Latest

# Skript liegt direkt im Audit-Ordner (audit/2026-10-01-fenster-flash/)
$auditDir = $PSScriptRoot
$repoRoot = Split-Path -Parent (Split-Path -Parent $auditDir)
$runtimeRoot = Join-Path $env:USERPROFILE '.tools'
$pass = 0
$fail = 0

function Assert-True {
	param([string]$Name, [bool]$Condition, [string]$Detail)
	if ($Condition) {
		Write-Host ("PASS {0}" -f $Name) -ForegroundColor Green
		$script:pass++
	} else {
		Write-Host ("FAIL {0}: {1}" -f $Name, $Detail) -ForegroundColor Red
		$script:fail++
	}
}

# 1) Live-Task-Aktion = Wrapper
$t = Get-ScheduledTask -TaskName 'Node Watchdog' -ErrorAction SilentlyContinue
if ($t) {
	$exec = $t.Actions[0].Execute
	$args1 = $t.Actions[0].Arguments
	Assert-True '1 Live-Task nutzt wscript.exe' ($exec -eq 'wscript.exe') "stattdessen: $exec"
	Assert-True '1 Arguments enthalten run-hidden.vbs' ($args1 -match 'run-hidden\.vbs') $args1
	Assert-True '1 Arguments enthalten node-watchdog.ps1' ($args1 -match 'node-watchdog\.ps1') $args1
	Assert-True '1 Arguments enthalten -Apply' ($args1 -match '-Apply') $args1

	# 2) Trigger unveraendert
	$iv = $t.Triggers[0].Repetition.Interval
	Assert-True '2 Trigger-Intervall PT10M' ($iv -eq 'PT10M') "stattdessen: $iv"

	# 4) Letzter Lauf
	$i = $t | Get-ScheduledTaskInfo
	Write-Host ("INFO Letzter Lauf: {0}  Ergebnis: 0x{1:X}" -f $i.LastRunTime, $i.LastTaskResult)
} else {
	Assert-True '1 Live-Task vorhanden' $false 'Task Node Watchdog nicht gefunden'
}

# 3) Laufhistorie-Raster
$log = Join-Path $runtimeRoot 'node-watchdog\node-watchdog.log'
if (Test-Path $log) {
	$starts = Get-Content $log | Select-String 'Start: Mode=APPLY' | Select-Object -Last 8
	$starts | ForEach-Object { Write-Host ("INFO " + $_.Line) }
	if ($starts.Count -ge 2) {
		$t0 = [datetime]::Parse($starts[-2].Line.Substring(0, 19))
		$t1 = [datetime]::Parse($starts[-1].Line.Substring(0, 19))
		$gap = ($t1 - $t0).TotalMinutes
		Assert-True '3 Laufabstand ca. 10 Minuten' ([math]::Abs($gap - 10) -lt 2) "gemessen: $gap Minuten"
	}
} else {
	Assert-True '3 Watchdog-Log vorhanden' $false $log
}

# 5) VORHER/NACHHER-XML
$vorher = Join-Path $auditDir '02-beweise\node-watchdog-VORHER.xml'
$nachher = Join-Path $auditDir '02-beweise\node-watchdog-NACHHER.xml'
if ((Test-Path $vorher) -and (Test-Path $nachher)) {
	$vh = Get-Content $vorher -Raw
	$nh = Get-Content $nachher -Raw
	Assert-True '5 VORHER enthaelt powershell.exe' ($vh -match '<Command>powershell\.exe</Command>') 'Muster nicht gefunden'
	Assert-True '5 NACHHER enthaelt wscript.exe' ($nh -match '<Command>wscript\.exe</Command>') 'Muster nicht gefunden'
	Assert-True '5 beide enthaelt PT10M' (($vh -match 'PT10M') -and ($nh -match 'PT10M')) 'Intervall-Abweichung'
	Assert-True '5 beide enthaelt PT5M-Limit' (($vh -match 'PT5M') -and ($nh -match 'PT5M')) 'ExecutionTimeLimit-Abweichung'
} else {
	Assert-True '5 XML-Beweise vorhanden' $false "vorher=$vorher nachher=$nachher"
}

# 6) Repo-Muster
$install = Join-Path $repoRoot 'scripts\install-task.ps1'
if (Test-Path $install) {
	$m = Select-String -Path $install -Pattern 'wscript\.exe'
	Assert-True '6 install-task.ps1 nutzt Wrapper-Muster' ($null -ne $m) 'kein wscript.exe-Muster gefunden'
} else {
	Write-Host ("INFO Repo nicht am erwarteten Ort: {0} (Pruefung 6 uebersprungen)" -f $install)
}

# 7) Rest-Migration (Blueprint-Slices 2-4): alle vier Tasks via Wrapper
$migrationTasks = @('MemoryIngest', 'NpmCleanup', 'ToolingCleanup', 'RoutedWatch')
foreach ($name in $migrationTasks) {
	$t7 = Get-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue
	if ($t7) {
		Assert-True ("7 {0} nutzt wscript.exe" -f $name) ($t7.Actions[0].Execute -eq 'wscript.exe') ("stattdessen: {0}" -f $t7.Actions[0].Execute)
		$args7 = $t7.Actions[0].Arguments
		Assert-True ("7 {0} Arguments enthalten run-hidden.vbs" -f $name) ($args7 -match 'run-hidden\.vbs') $args7
	} else {
		Assert-True ("7 {0} vorhanden" -f $name) $false 'Task nicht gefunden'
	}
}
$repoTaskDir = Join-Path $repoRoot 'task'
$missingBackups = @($migrationTasks | Where-Object { -not (Test-Path (Join-Path $repoTaskDir ($_.Name + '.xml'))) })
if ($missingBackups.Count -eq 0) {
	$stale = @()
	foreach ($name in $migrationTasks) {
		$bk = Get-Content (Join-Path $repoTaskDir ($name + '.xml')) -Raw
		if ($bk -notmatch '<Command>wscript\.exe</Command>') { $stale += $name }
	}
	Assert-True '7 Repo-Backups task\\*.xml auf wscript' ($stale.Count -eq 0) ("stale: {0}" -f ($stale -join ','))
} else {
	Assert-True '7 Repo-Backups vorhanden' $false ($missingBackups -join ',')
}

# 10) TaskScheduler-Historie aktiv
$logStatus = wevtutil.exe get-log 'Microsoft-Windows-TaskScheduler/Operational' 2>$null
$enabledLine = $logStatus | Select-String 'enabled: true'
Assert-True '10 Historie aktiviert' ($null -ne $enabledLine) ($logStatus | Select-String 'enabled' | ForEach-Object Line)
$evts = Get-WinEvent -LogName 'Microsoft-Windows-TaskScheduler/Operational' -MaxEvents 3 -ErrorAction SilentlyContinue
if ($evts) {
	Assert-True '10 Events fließen' ($evts.Count -gt 0) 'keine Events im Log'
	$evts | ForEach-Object { Write-Host ("INFO {0} id={1}" -f $_.TimeCreated.ToString('HH:mm:ss'), $_.Id) }
} else {
	Write-Host 'INFO Historie aktiv, noch keine Events (naechster Task-Lauf liefert sie)'
}

Write-Host ''
Write-Host ("Ergebnis: {0} PASS, {1} FAIL" -f $pass, $fail)
if ($fail -gt 0) { exit 1 }
exit 0
