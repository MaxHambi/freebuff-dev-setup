#Requires -Version 7.4
# run.ps1 - Einstiegspunkt des NextDNS-Managers.
#
# Ohne -Action startet der interaktive Menue-Modus (Slice #41 baut die
# CLI-Parameter hier aus; vor #38 liefert -Action einen Hinweis und Exit 2).

[CmdletBinding()]
param(
	[string]$Action,
	[object]$ApiConfig
)

$ErrorActionPreference = 'Stop'

$modulePath = Join-Path -Path $PSScriptRoot -ChildPath 'NextDnsManager.psd1'
Import-Module $modulePath -Force -ErrorAction Stop

if ($Action) {
	Write-Host "CLI-Modus (-Action $Action) wird in Slice #41 (Issue #41) ausgebaut." -ForegroundColor Yellow
	Write-Host 'Bis dahin bitte den interaktiven Modus nutzen (run.ps1 ohne -Action).' -ForegroundColor Yellow
	exit 2
}

# Interaktiver Menue-Modus (Funktion folgt in #41; bis dahin Hinweis)
if (Get-Command Show-NextDnsMenu -ErrorAction SilentlyContinue) {
	Show-NextDnsMenu
} else {
	Write-Host 'Menue-Modus folgt in Slice #41 (Issue #41).' -ForegroundColor Yellow
	Write-Host 'Modul-Geruest ist installiert; Import-Check:' -ForegroundColor Yellow
	Get-Command -Module NextDnsManager | ForEach-Object { Write-Host "  - $($_.Name)" }
}
exit 0
