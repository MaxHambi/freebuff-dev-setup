#Requires -Version 5.1
# Audit 2026-10-01-fenster-flash / P12: Verifikation des 16:30-Laufs von
# MemoryIngest nach der run-hidden.vbs-Migration. Read-only: sammelt nur
# Ist-Zustand und Logzeilen, am System wird nichts geaendert.
#
# Aufruf:
#   pwsh -File memoryingest-1630-verifikation.ps1
#       wartet per Polling, bis der 16:30-Lauf belegt ist, sammelt dann alle
#       Beweise (Deadline 17:15 - danach wird der Ist-Zustand ehrlich
#       protokolliert, was da ist)
#   pwsh -File memoryingest-1630-verifikation.ps1 -NoWait
#       sammelt den Ist-Zustand sofort
#
# Ausgabe: 02-beweise/migration/memoryingest-1630-verifikation.txt
# Status:  $env:TEMP/memoryingest-verify-status.txt (Herzschlag beim Warten)

param([switch]$NoWait)

$ErrorActionPreference = 'Continue'
$auditRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$outFile = Join-Path $auditRoot '02-beweise/migration/memoryingest-1630-verifikation.txt'
$statusFile = Join-Path $env:TEMP 'memoryingest-verify-status.txt'

function Emit { param([string]$Text) $Text | Tee-Object -FilePath $outFile -Append | Out-Null }

Set-Content -Path $outFile -Value ("MemoryIngest-Verifikation (P12) - erzeugt {0} - Modus: {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $(if ($NoWait) { 'NoWait' } else { 'Wait' }))
Emit ''

# Phase 1: auf den 16:30-Lauf warten (Polling alle 20 s, Abbruch 17:15)
if (-not $NoWait) {
	$target = Get-Date -Hour 16 -Minute 29 -Second 0
	$deadline = Get-Date -Hour 17 -Minute 15 -Second 0
	Set-Content -Path $statusFile -Value ("warte auf LastRun >= {0} (Deadline {1})" -f $target.ToString('HH:mm'), $deadline.ToString('HH:mm'))
	while ($true) {
		$now = Get-Date
		$info = Get-ScheduledTaskInfo -TaskName MemoryIngest
		$task = Get-ScheduledTask -TaskName MemoryIngest
		$runDone = $info.LastRunTime -ge $target
		$quiet = $task.State -ne 'Running'
		if (($runDone -and $quiet) -or ($now -ge $deadline)) { break }
		Set-Content -Path $statusFile -Value ("{0} LastRun={1} State={2}" -f $now.ToString('HH:mm:ss'), $info.LastRunTime.ToString('HH:mm:ss'), $task.State)
		Start-Sleep -Seconds 20
	}
	Set-Content -Path $statusFile -Value ("{0} Wartephase beendet - sammle Beweise" -f (Get-Date -Format 'HH:mm:ss'))
}

# Phase 2: Beweise sammeln
Emit '== 1) Get-ScheduledTaskInfo MemoryIngest =='
try {
	$info = Get-ScheduledTaskInfo -TaskName MemoryIngest
	Emit (($info | Format-List TaskName, LastRunTime, LastTaskResult, NextRunTime, NumberOfMissedRuns | Out-String).TrimEnd())
	Emit ("LastTaskResult hex: 0x{0:X}" -f $info.LastTaskResult)
}
catch { Emit ("FEHLER: {0}" -f $_.Exception.Message) }

Emit ''
Emit '== 2) Task-State und Aktion (Live, Wrapper-Nachweis) =='
try {
	$task = Get-ScheduledTask -TaskName MemoryIngest
	Emit ("State: {0}" -f $task.State)
	foreach ($a in $task.Actions) {
		Emit ("Execute:   {0}" -f $a.Execute)
		Emit ("Arguments: {0}" -f $a.Arguments)
	}
}
catch { Emit ("FEHLER: {0}" -f $_.Exception.Message) }

Emit ''
Emit '== 3) TaskScheduler-Operational-Events fuer MemoryIngest (ab 16:20) =='
try {
	$events = Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-TaskScheduler/Operational'; StartTime = (Get-Date -Hour 16 -Minute 20 -Second 0) } -ErrorAction Stop |
		Where-Object { $_.Message -match 'MemoryIngest' } |
		Select-Object -First 20
	if ($events) {
		foreach ($e in $events) {
			$firstLines = ($e.Message -split "`r?`n" | Where-Object { $_.Trim() -ne '' } | Select-Object -First 2) -join ' | '
			Emit ("{0}  Id={1}  {2}" -f $e.TimeCreated.ToString('HH:mm:ss'), $e.Id, $firstLines)
		}
	}
	else { Emit 'keine MemoryIngest-Events im Zeitfenster gefunden' }
}
catch { Emit ("Event-Log nicht lesbar: {0}" -f $_.Exception.Message) }

Emit ''
Emit '== 4) Runtime-Log des Ingest (neueste *.log unter .tools/memory-ingest, letzte 15 Zeilen) =='
try {
	$logDir = Join-Path $env:USERPROFILE '.tools/memory-ingest'
	$log = Get-ChildItem -Path $logDir -Filter '*.log' -ErrorAction Stop | Sort-Object LastWriteTime -Descending | Select-Object -First 1
	if ($log) {
		Emit ("Datei: {0}" -f $log.FullName)
		Get-Content -Path $log.FullName -Tail 15 | ForEach-Object { Emit $_ }
	}
	else { Emit 'kein *.log unter .tools/memory-ingest gefunden' }
}
catch { Emit ("Log nicht lesbar: {0}" -f $_.Exception.Message) }

Emit ''
Emit 'Quelle: audit/2026-10-01-fenster-flash/memoryingest-1630-verifikation.ps1 (read-only)'
Set-Content -Path $statusFile -Value ("{0} FERTIG" -f (Get-Date -Format 'HH:mm:ss'))
exit 0
