#Requires -Version 5.1
# Export: sichert die eigenen Scheduled Tasks als XML nach task\<Name>.xml.
# Diese XMLs sind das Backup fuer die GUI-Wiederherstellung
# (Aufgabenplanung -> Aufgabe importieren...).

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Split-Path -Parent $PSScriptRoot
$taskDir = Join-Path $repoRoot 'task'
New-Item -ItemType Directory -Force -Path $taskDir | Out-Null

$taskNames = @(
	'Node Watchdog',
	'NpmCleanup',
	'ToolingCleanup',
	'RoutedWatch',
	'MemoryIngest'
)

$exported = 0
foreach ($name in $taskNames) {
	$xml = schtasks.exe /query /tn $name /xml 2>$null
	if ($LASTEXITCODE -ne 0 -or -not $xml) {
		Write-Host ("SKIP {0} (Task nicht registriert)" -f $name) -ForegroundColor Yellow
		continue
	}
	$fileName = ($name -replace '[\\/:*?"<>|]', '_') + '.xml'
	$path = Join-Path $taskDir $fileName
	$xml | Set-Content -Path $path -Encoding Unicode
	Write-Host ("EXPORT {0} -> task\{1}" -f $name, $fileName)
	$exported++
}

Write-Host ("{0} Task-Definition(en) exportiert." -f $exported)
exit 0
