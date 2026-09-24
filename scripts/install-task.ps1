#Requires -Version 5.1
# Task-Registrierung: legt die Scheduled Tasks auf die Runtime-Pfade in
# %USERPROFILE%\.tools. Implementierungs-Sitzung baut die einzelnen Tasks
# laut plan.md aus (Slices T2-T6). Vorlage zeigt das Muster fuer den Watchdog.

param(
	[Parameter(Mandatory = $false)]
	[string]$Task = 'Node Watchdog'
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
}

if (-not $taskMap.ContainsKey($Task)) {
	Write-Host ("Unbekannter Task '{0}'. Bekannt: {1}" -f $Task, ($taskMap.Keys -join ', ')) -ForegroundColor Red
	exit 1
}

$scriptPath = Join-Path $runtimeRoot $taskMap[$Task]
if (-not (Test-Path $scriptPath)) {
	Write-Host ("Skript fehlt: {0} - zuerst deploy.ps1 ausfuehren." -f $scriptPath) -ForegroundColor Red
	exit 1
}

$action = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""
Write-Host ("Registriere '{0}' -> {1}" -f $Task, $scriptPath)
Write-Host ("Aktion: {0}" -f $action)
Write-Host 'Hinweis: Trigger/Intervalle je Slice in der Implementierungs-Sitzung ergaenzen.'
exit 0
