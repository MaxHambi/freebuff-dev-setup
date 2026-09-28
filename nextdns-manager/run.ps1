#Requires -Version 7.4
# run.ps1 - Einstiegspunkt des NextDNS-Managers.
#
# Zwei Modi:
#   1. Menue-Modus (Default):            pwsh -File run.ps1
#   2. CLI-Modus (non-interaktiv):       pwsh -File run.ps1 -Action <Name> [-ActionParameter @{...}]
#
# Exit-Codes (dokumentiert, Issue #41):
#   0 = Erfolg
#   1 = API-Fehler (Fehler-Objekt der API-Schicht)
#   2 = Konfigurations-/Umgebungsfehler (Secrets, Font egal, unbekannte Action)

[CmdletBinding()]
param(
	[string]$Action,
	# Parameter fuer die Action als Hashtabelle (nur aus PowerShell heraus):
	# -ActionParameter @{ Limit = 50; Status = 'blocked' }
	[hashtable]$ActionParameter,
	# Cross-shell-Variante (bash/cmd/JSON-Dateien): JSON-String statt
	# Hashtabelle, da pwsh -File Argumente verbatim als Strings uebergibt
	# und '@{...}' nicht parst: -ActionParameterJson '{"Limit":50}'
	[string]$ActionParameterJson,
	# Icons erzwingen (Default: Auto-Erkennung Nerd Font / ASCII-Fallback)
	[switch]$NoIcons,
	[switch]$Version
)

$ErrorActionPreference = 'Stop'

$modulePath = Join-Path -Path $PSScriptRoot -ChildPath 'NextDnsManager.psd1'
Import-Module $modulePath -Force -ErrorAction Stop

if ($Version) {
	$manifest = Import-PowerShellDataFile -Path $modulePath
	Write-Output "NextDnsManager $($manifest.ModuleVersion)"
	exit 0
}

# Icons initialisieren (Nerd-Font-Erkennung oder ASCII-Fallback)
Initialize-NextDnsIcons -NoIcons:$NoIcons

# --- Menue-Modus ---
if (-not $Action) {
	if ([Console]::IsOutputRedirected -or -not [Environment]::UserInteractive) {
		# Hinweis: kein Write-Error (EAP=Stop wuerde werfen und den Exit-Code kippen)
		Write-Host 'x Kein interaktiver Host: bitte -Action angeben (CLI-Modus).' -ForegroundColor Red
		exit 2
	}
	Show-NextDnsMenu
	exit 0
}

# --- CLI-Modus ---
try {
	$null = Get-NextDnsConfig
	if (-not (Test-NextDnsConfigReady)) {
		$null = Connect-NextDnsApi
	}
} catch {
	Write-Host "x Konfiguration unvollstaendig: $($_.Exception.Message)" -ForegroundColor Red
	Write-Host '  Setup: pwsh -File setup.ps1' -ForegroundColor Yellow
	exit 2
}

$table = Get-NextDnsMenuTable

# CLI-Komfort-Aliase (freundliche Namen -> Tabellen-Eintraege)
$aliases = @{
	'Get-Profiles' = '2'
	'Get-Profile' = '1'
	'Get-Settings' = '3'
	'Get-Blocklists' = '4'
	'Get-Denylist' = '5'
	'Get-Allowlist' = '6'
	'Get-Logs' = '7'
	'Get-Analytics' = '8'
	'Get-AllAnalytics' = '9'
	'Test-Connection' = 'A'
	'Export-Logs' = 'B'
	'Export-Report' = 'C'
	'Add-Denylist' = 'D'
	'Remove-Denylist' = 'E'
	'Add-Allowlist' = 'F'
	'Set-Profile' = 'G'
	'Clear-Logs' = 'H'
}

$key = $Action
if ($aliases.ContainsKey($Action)) { $key = $aliases[$Action] }

$entry = $table | Where-Object { $_.Key -eq $key } | Select-Object -First 1
if (-not $entry) {
	Write-Host "x Unbekannte Action '$Action'. Verfuegbar: $($aliases.Keys -join ', ')" -ForegroundColor Red
	exit 2
}

# Im CLI-Modus keine interaktiven Prompts: Aktionen mit Prompt-Plan werden
# direkt mit -ActionParameter (oder sensible Defaults) ausgefuehrt.

# Parameter zusammenfuehren (Hashtabelle + JSON) - VOR dem Mandatory-Check,
# damit JSON-Parameter korrekt angerechnet werden (Reihenfolge-Bug aus dem
# Live-Smoke: Check sah nur die Hashtabelle, JSON-Parameter wurden ignoriert).
$callParams = @{}
if ($ActionParameter) { $callParams = $ActionParameter }
if ($ActionParameterJson) {
	try {
		$parsed = $ActionParameterJson | ConvertFrom-Json -AsHashtable -ErrorAction Stop
		foreach ($k in $parsed.Keys) { $callParams[$k] = $parsed[$k] }
	} catch {
		Write-Host "x ActionParameterJson ist kein gueltiges JSON: $($_.Exception.Message)" -ForegroundColor Red
		exit 2
	}
}

# Mandatory-Parameter der Zielfunktion pruefen (verhindert den interaktiven
# Mandatory-Prompt, der in Non-Interactive-Hosts haengen wuerde - Befund 9).
$fn = Get-Command $entry.Function -ErrorAction SilentlyContinue
if ($fn) {
	$missingMandatory = @()
	foreach ($p in $fn.Parameters.Values) {
		$isMandatory = $p.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] -and $_.Mandatory }
		if ($isMandatory -and -not $callParams.ContainsKey($p.Name)) {
			$missingMandatory += $p.Name
		}
	}
	if ($missingMandatory) {
		Write-Host "x Action '$Action' benoetigt: $($missingMandatory -join ', ')" -ForegroundColor Red
		Write-Host "  Uebergabe: -ActionParameterJson '{\"$($missingMandatory[0])\":\"<wert>\"}'" -ForegroundColor Yellow
		exit 2
	}
}

try {
	$result = & $entry.Function @callParams

	# Write-Funktionen liefern je-Domain-Ergebnisse: ein Fehler -> Exit 1
	$results = @($result)
	$failed = $results | Where-Object { $_ -and $_.PSObject.Properties['Ok'] -and -not $_.Ok }
	if ($failed) {
		foreach ($f in $failed) { Write-Host "x $($f.Domain): $($f.Error)" -ForegroundColor Red }
		exit 1
	}

	# Read-Funktionen liefern Result-/AllPages-Objekte
	$first = $results | Where-Object { $_ -and ($_.PSObject.Properties['Ok'] -or $_.PSObject.Properties['Entries']) } | Select-Object -First 1
	if ($first) {
		if ($first.PSObject.Properties['Ok'] -and -not $first.Ok) {
			Write-Host "x $($first.Error)" -ForegroundColor Red
			exit 1
		}
		if ($first.PSObject.Properties['Entries'] -and $first.Error) {
			Write-Host "x $($first.Error)" -ForegroundColor Red
			exit 1
		}
	}

	# Erfolg -> kompakte Ausgabe
	Show-NextDnsResult -Result $result -Title $entry.Label
	exit 0
} catch {
	Write-Host "x $($_.Exception.Message)" -ForegroundColor Red
	exit 1
}
