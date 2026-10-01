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
	'NpmCleanup'           = 'maintenance\npm-cleanup.ps1'
	'ToolingCleanup'       = 'maintenance\tooling-cleanup.ps1'
	'RoutedWatch'          = 'routed-watch\watch-wrapper.ps1'
	'MemoryIngest'         = 'memory-ingest\ingest.ps1'
}

# Task-Name -> Trigger (ST = Start-Time). Retry-Intervall in Minuten.
$triggerMap = @{
	'Node Watchdog'      = 'ST=00:00; Interval=10min; Duration=1d'
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

$vbsPath = Join-Path $runtimeRoot 'maintenance\run-hidden.vbs'
if (-not (Test-Path $vbsPath)) {
	Write-Host ("Wrapper fehlt: {0} - zuerst deploy.ps1 ausfuehren." -f $vbsPath)
	exit 1
}

# Fenster-Flash-Fix (2026-10-01): Task-Aktionen laufen ueber run-hidden.vbs
# (wscript, SW_HIDE ab Prozessstart) statt direkt powershell.exe. Direkte
# Konsolenaufrufe erzeugen das conhost-Fenster sichtbar, bevor -WindowStyle
# Hidden greift. Alle Task-Argumente (inkl. Watchdog -Apply) wandern als
# VBS-Argumente 2..n durch.
$taskArgs = @()
if ($Task -eq 'Node Watchdog') { $taskArgs += '-Apply' }

$quotedScript = '"' + $scriptPath + '"'
$argSuffix = ($taskArgs | ForEach-Object { '"' + $_ + '"' }) -join ' '
$action = "wscript.exe //B //Nologo `"$vbsPath`" $quotedScript $argSuffix".Trim()

Write-Host ("Registriere '{0}' -> {1}" -f $Task, $scriptPath)
Write-Host ("Trigger-Vorlage: {0}" -f $triggerMap[$Task])

if (-not $Register) {
	Write-Host ("Aktion: {0}" -f $action)
	Write-Host 'Vorschau (-Register zum Anlegen/Aktualisieren der Aufgabe).'
	exit 0
}

# ---------------------------------------------------------------- schtasks / Register-ScheduledTask
$trigger = $triggerMap[$Task]

if ($trigger -eq 'AtLogon') {
	# AtLogon als per-user-Aufgabe: schtasks /SC ONLOGON legt eine any-user-Aufgabe
	# an und verlangt Admin ("Zugriff verweigert"). Register-ScheduledTask mit
	# InteractiveToken-Principal registriert ohne Hoehenrecht - siehe #32 (T4).
	$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited
	$taskAction = New-ScheduledTaskAction -Execute 'wscript.exe' `
		-Argument ('//B //Nologo "{0}" "{1}"' -f $vbsPath, $scriptPath)
	$logonTrigger = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
	$settings = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew `
		-ExecutionTimeLimit (New-TimeSpan -Seconds 0) `
		-AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
		-RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
	Register-ScheduledTask -TaskName $Task -Action $taskAction -Trigger $logonTrigger `
		-Settings $settings -Principal $principal -Force | Out-Null
	Write-Host ("Aufgabe '{0}' registriert (per-user AtLogon)." -f $Task)
	exit 0
}

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

# StartWhenAvailable nachziehen: schtasks kennt dafuer keinen Schalter; per
# Set-ScheduledTask + Settings-Objekt geht es ohne Hoehenrecht. Verpasste
# Trigger (Laptop aus, Busy) werden sonst als 0x41303/0x800710E0 gemeldet,
# ohne nachgeholt zu werden (Slice-6-Befund). ExecutionTimeLimit: plan.md
# bindend 5 Min fuer den Watchdog, sonst 1 h.
try {
	$limit = if ($Task -eq 'Node Watchdog') { (New-TimeSpan -Minutes 5) } else { (New-TimeSpan -Hours 1) }
	$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew `
		-ExecutionTimeLimit $limit -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
	Set-ScheduledTask -TaskName $Task -Settings $settings | Out-Null
	Write-Host ("StartWhenAvailable + ExecutionTimeLimit gesetzt fuer '{0}'." -f $Task)
} catch {
	Write-Host ("WARN Settings-Nachbesserung fehlgeschlagen: {0}" -f $_) -ForegroundColor Yellow
}
if ($LASTEXITCODE -ne 0) {
	Write-Host ("Registrierung fehlgeschlagen (schtasks Exit {0})." -f $LASTEXITCODE) -ForegroundColor Red
	exit $LASTEXITCODE
}
Write-Host ("Aufgabe '{0}' registriert." -f $Task)
exit 0
