#Requires -Version 5.1
# Syntaxcheck: parst alle PowerShell-Skripte im Repo ohne sie auszufuehren.
# Exit 1, wenn ein Skript Parserfehler enthaelt.

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Split-Path -Parent $PSScriptRoot
$scripts = Get-ChildItem -Path $repoRoot -Recurse -Filter '*.ps1' |
	Where-Object { $_.FullName -notmatch '\\node_modules\\|\\\.git\\' }

$failed = 0
foreach ($script in $scripts) {
	$tokens = $null
	$errors = $null
	$null = [System.Management.Automation.Language.Parser]::ParseFile(
		$script.FullName, [ref]$tokens, [ref]$errors)
	if ($errors.Count -gt 0) {
		$failed++
		Write-Host ("FAIL {0}" -f $script.FullName) -ForegroundColor Red
		foreach ($err in $errors) {
			Write-Host ("  {0} (Zeile {1})" -f $err.Message, $err.Extent.StartLineNumber)
		}
	} else {
		Write-Host ("OK   {0}" -f $script.FullName)
	}
}

if ($scripts.Count -eq 0) {
	Write-Host 'Keine PowerShell-Skripte gefunden - nichts zu pruefen.'
	exit 0
}

if ($failed -gt 0) {
	Write-Host ("{0} von {1} Skript(en) mit Fehlern." -f $failed, $scripts.Count) -ForegroundColor Red
	exit 1
}
Write-Host ("Alle {0} PowerShell-Skripte syntaktisch in Ordnung." -f $scripts.Count) -ForegroundColor Green
exit 0
