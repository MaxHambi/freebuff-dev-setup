#Requires -Version 5.1
# migrate-tasks.ps1 - Migration der vier Rest-Tasks auf den run-hidden.vbs-Wrapper.
# Blueprint: docs/plan-2026-10-01-fenster-flash-migration.md, Slices 2-4.
#
# Pro Task: VORHER-XML sichern (falls nicht vorhanden) -> Command/Arguments
# patchen -> XML-Validierung -> Re-Import (Trigger/Principal/Settings bleiben
# byte-identisch) -> NACHHER-XML + Live-Check protokollieren.
# RoutedWatch ist ein Dauerprozess: vorher Stop-ScheduledTask, danach Start.
#
# Aufruf: pwsh -NoProfile -File migrate-tasks.ps1 [-TaskList MemoryIngest,NpmCleanup,...]

param(
	[string[]]$TaskList = @('MemoryIngest', 'NpmCleanup', 'ToolingCleanup', 'RoutedWatch')
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$runtimeRoot = Join-Path $env:USERPROFILE '.tools'
$vbsPath = Join-Path $runtimeRoot 'maintenance\run-hidden.vbs'
$migrationDir = Join-Path $PSScriptRoot '02-beweise\migration'
New-Item -ItemType Directory -Force -Path $migrationDir | Out-Null

if (-not (Test-Path $vbsPath)) { throw "Wrapper fehlt: $vbsPath" }

# Task -> Runtime-Skript (relativ zum Runtime-Root)
$taskMap = @{
	'MemoryIngest'   = 'memory-ingest\ingest.ps1'
	'NpmCleanup'     = 'maintenance\npm-cleanup.ps1'
	'ToolingCleanup' = 'maintenance\tooling-cleanup.ps1'
	'RoutedWatch'    = 'routed-watch\watch-wrapper.ps1'
}

$results = @()
foreach ($task in $TaskList) {
	Write-Host "=== $task ==="
	$scriptPath = Join-Path $runtimeRoot $taskMap[$task]
	if (-not (Test-Path $scriptPath)) { throw "Skript fehlt: $scriptPath" }

	# 1) VORHER-XML (falls nicht schon beim ersten Lauf gesichert)
	$vorher = Join-Path $migrationDir "VORHER-$task.xml"
	if (-not (Test-Path $vorher)) {
		$null = schtasks.exe /query /tn $task /xml | Out-File -FilePath $vorher -Encoding Unicode
	}
	$xmlRaw = Get-Content $vorher -Raw
	$null = [xml]$xmlRaw  # VORHER muss validieren

	# 2) Patch nur Command + Arguments; Rest byte-identisch. String-Ersatz
	# via .Replace (kein Regex), da die Pfade Backslashes enthalten.
	$wrapperArgs = '//B //Nologo "{0}" "{1}"' -f $vbsPath, $scriptPath
	$oldArgsMarker = '<Arguments>-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $scriptPath + '"'
	$patched = $xmlRaw.
		Replace('<Command>powershell.exe</Command>', '<Command>wscript.exe</Command>').
		Replace($oldArgsMarker, '<Arguments>' + $wrapperArgs)
	if ($patched -eq $xmlRaw) { throw "$task : Arguments-Muster nicht gefunden (unerwartetes XML-Layout)" }
	$null = [xml]$patched  # NACHHER muss validieren

	if ($patched -notmatch '<Command>wscript\.exe</Command>') { throw "$task : Patch auf wscript.exe fehlgeschlagen" }
	if ($patched -notmatch [regex]::Escape('run-hidden.vbs')) { throw "$task : Wrapper-Argument fehlt im Patch" }

	# 3) Dauerprozess stoppen, Re-Import, wieder starten
	$wasRunning = $false
	if ($task -eq 'RoutedWatch') {
		$state = (Get-ScheduledTask -TaskName $task).State
		if ($state -eq 'Running') {
			$wasRunning = $true
			Stop-ScheduledTask -TaskName $task
			Start-Sleep -Seconds 2
			Write-Host "  laufende Instanz gestoppt (war Running)"
		}
	}
	$schXml = Join-Path $env:TEMP "migrate-$task.xml"
	Set-Content -Path $schXml -Value $patched -Encoding Unicode
	$null = schtasks.exe /create /tn $task /xml $schXml /f
	if ($LASTEXITCODE -ne 0) { throw "$task : Re-Import fehlgeschlagen (Exit $LASTEXITCODE)" }
	if ($wasRunning) {
		Start-ScheduledTask -TaskName $task
		Start-Sleep -Seconds 3
	}

	# 4) NACHHER-XML + Live-Check
	$nachher = Join-Path $migrationDir "NACHHER-$task.xml"
	$null = schtasks.exe /query /tn $task /xml | Out-File -FilePath $nachher -Encoding Unicode
	$t = Get-ScheduledTask -TaskName $task
	$i = $t | Get-ScheduledTaskInfo
	$exec = $t.Actions[0].Execute
	$state2 = $t.State
	$line = '{0} | Exec={1} | State={2} | LastRun={3} | Result=0x{4:X}' -f $task, $exec, $state2, $i.LastRunTime, $i.LastTaskResult
	Write-Host ("  " + $line)
	$results += $line

	if ($exec -ne 'wscript.exe') { throw "$task : Action ist weiterhin $exec" }
}

$report = Join-Path $migrationDir 'migration-livecheck.txt'
$results | Set-Content -Path $report -Encoding utf8
Write-Host ""
Write-Host "Live-Check protokolliert: $report"
exit 0
