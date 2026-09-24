#Requires -Version 5.1
# Test-Einstieg: fuehrt alle repo-seitigen Verifikationen aus.
# Implementierungs-Sitzung: hier konkrete Pester-/Integrationstests ergaenzen
# (siehe plan.md, Slice T1: DryRun-Report, Orphan-Test, Port-Test, Whitelist).
# Ohne Tests exit 0, damit CI/Hook bis dahin gruen bleiben.

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Split-Path -Parent $PSScriptRoot

# 1) Watchdog-DryRun nur auf Windows ausfuehren (Get-CimInstance ist Windows-only).
$watchdog = Join-Path $repoRoot 'node-watchdog\node-watchdog.ps1'
$isWindowsPlatform = [System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT
if ($isWindowsPlatform -and (Test-Path $watchdog)) {
	$output = & pwsh -NoProfile -File $watchdog 2>&1
	if ($LASTEXITCODE -ne 0) {
		Write-Host "FAIL: Watchdog-DryRun brach mit Exit $LASTEXITCODE ab." -ForegroundColor Red
		$output | ForEach-Object { Write-Host $_ }
		exit 1
	}
	Write-Host 'OK   node-watchdog.ps1 DryRun laeuft (kein Kill ohne -Apply).'
} else {
	Write-Host 'SKIP node-watchdog.ps1 noch nicht vorhanden (Slice T1 offen).'
}
if (-not $isWindowsPlatform) {
	Write-Host 'SKIP node-watchdog.ps1 DryRun (nur Windows - Get-CimInstance nicht verfuegbar).'
}

Write-Host 'Testlauf abgeschlossen.'
exit 0
