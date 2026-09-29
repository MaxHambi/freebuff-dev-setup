#Requires -Version 5.1
# Task-Registrierung: legt die Scheduled Tasks auf die Runtime-Pfade in
# %USERPROFILE%\.tools an. Ohne -Register nur Vorschau (Aktion + Trigger).
# Die XML-Backups liefert export-tasks.ps1 nach task\<Name>.xml.
#
# Beispiele:
#   pwsh -File install-task.ps1 -Task MemoryIngest            # Vorschau
#   pwsh -File install-task.ps1 -Task MemoryIngest -Register  # anlegen/aktualisieren

param(
	[Parameter(Mandatory = $false)]
	[string]$Task = 'Node Watchdog',
	[switch]$Register
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$runtimeRoot = Join-Path $env:USERPROFILE '.tools'

# Task-Name -> Script-Pfad (relativ zum Runtime-Root)
$taskMap = @{
	'Node Watchdog'        = 'node-watchdog\node-watchdog.ps1'
	'NodeProcessMonitor'   = 'node-monitor\node-monitor.ps1'
	'NpmCleanup'           = 'maintenance\npm-cleanup.ps1'
	'ToolingCleanup'       = 'maintenance\tooling-cleanup.ps1'
	'RoutedWatch'          = 'routed-watch\watch-wrapper.ps1'
	'MemoryIngest'         = 'memory-ingest\ingest.ps1'
}

# Task-Name -> Trigger (ST = Start-Time). Retry-Intervall in Minuten.
$triggerMap = @{
	'Node Watchdog'      = 'ST=00:00; Interval=10min; Duration=1d'
	'NodeProcessMonitor' = 'ST=00:00; Interval=5min; Duration=1d'
	'NpmCleanup'         = 'ST=03:00; OnceDaily'
	'ToolingCleanup'     = 'ST=04:00; OnceDaily'
	'RoutedWatch'        = 'AtLogon'
	'MemoryIngest'       = 'ST=04:30; Interval=240min; Duration=1d'
}

if (-not $taskMap.ContainsKey($Task)) {
	Write-Host ("Unbekannter Task '{0}'. Bekannt: {1}" -f $Task, ($taskMap.Keys -join ', ')) -ForegroundColor Red
	exit 1
}

$scriptPath = Join-Path $runtimeRoot $taskMap[$Task]
if (-not (Test-Path $scriptPath)) {
	Write-Host ("Skript fehlt: {0} - zuerst deploy.ps1 ausfuehren." -f $scriptPath)
	exit 1
}

$action = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""

Write-Host ("Registriere '{0}' -> {1}" -f $Task, $scriptPath)
Write-Host ("Trigger-Vorlage: {0}" -f $triggerMap[$Task])

if (-not $Register) {
	Write-Host ("Aktion: {0}" -f $action)
	Write-Host 'Vorschau (-Register zum Anlegen/Aktualisieren der Aufgabe).'
	exit 0
}

# ---------------------------------------------------------------- schtasks
$trigger = $triggerMap[$Task]
$triggerArgs = @()
foreach ($part in $trigger -split '; ') {
	if ($part -like 'ST=*') { $triggerArgs += @('/ST', $part.Substring(3)) }
	if ($part -eq 'OnceDaily') { $triggerArgs += @('/SC', 'DAILY') }
	if ($part -eq 'AtLogon') { $triggerArgs += @('/SC', 'ONLOGON') }
	if ($part -like 'Interval=*') {
		$minutes = ($part -replace 'Interval=', '') -replace '(min|h)$', ''
		if ($part -match 'h$') { $minutes = [string]([int]$minutes * 60) }
		$triggerArgs += @('/SC', 'MINUTE', '/MO', $minutes)
	}
}

# /F ueberschreibt existierende Definitionen; /RL LIMITED (kein Hoehenrecht)
& schtasks.exe /Create /TN $Task /TR $action @triggerArgs /F /RL LIMITED
if ($LASTEXITCODE -ne 0) {
	Write-Host ("Registrierung fehlgeschlagen (schtasks Exit {0})." -f $LASTEXITCODE) -ForegroundColor Red
	exit $LASTEXITCODE
}
Write-Host ("Aufgabe '{0}' registriert." -f $Task)
exit 0
