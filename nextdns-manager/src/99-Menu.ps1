# 99-Menu.ps1 - Dispatch-Tabelle + interaktives Menue.
#
# Design (PLAN Befund 8/9): I/O getrennt von Logik. Die Dispatch-Tabelle
# ist deklarativ (Name -> Function + Prompt-Plan); das Ausfuehren ist ein
# kleiner Interpreter. Show-NextDnsResult kapselt die Konsolausgabe von
# Result-Objekten fuer ALLE Modi.

function Get-NextDnsMenuTable {
	<#
	.SYNOPSIS
		Deklarative Menue-Tabelle (pure, testbar). Order = Anzeigereihenfolge.
		Felder: Key, Label, Function, Parameter (ScriptBlock -> Hashtabelle
		mit Prompts), Confirm (Text fuer schreibende Actions).
	#>
	[CmdletBinding()]
	param()
	return @(
		[PSCustomObject]@{ Key = '1'; Label = 'Profil-Details'; Function = 'Get-NextDnsProfile'; Parameters = $null; Kind = 'read' }
		[PSCustomObject]@{ Key = '2'; Label = 'Alle Profile'; Function = 'Get-NextDnsProfiles'; Parameters = $null; Kind = 'read' }
		[PSCustomObject]@{ Key = '3'; Label = 'Einstellungen'; Function = 'Get-NextDnsSettings'; Parameters = $null; Kind = 'read' }
		[PSCustomObject]@{ Key = '4'; Label = 'Blocklisten'; Function = 'Get-NextDnsBlocklists'; Parameters = $null; Kind = 'read' }
		[PSCustomObject]@{ Key = '5'; Label = 'Denylist'; Function = 'Get-NextDnsDenylist'; Parameters = $null; Kind = 'read' }
		[PSCustomObject]@{ Key = '6'; Label = 'Allowlist'; Function = 'Get-NextDnsAllowlist'; Parameters = $null; Kind = 'read' }
		[PSCustomObject]@{ Key = '7'; Label = 'DNS-Logs (Filter)'; Function = 'Get-NextDnsLogs'; Parameters = {
				$limit = Read-NextDnsInt -Prompt 'Anzahl (Standard 100, 10..1000)' -Default 0
				$status = Read-NextDnsChoice -Prompt 'Status (default/error/blocked/allowed, leer=alle)' -Valid @('', 'default', 'error', 'blocked', 'allowed')
				$search = Read-Host 'Suchbegriff (leer=alle)'
				$raw = (Read-Host 'Alle Queries inkl. Rauschen? (j/N)') -match '^[jJyY]'
				@{ Limit = $limit; Status = $status; Search = $search; Raw = $raw }
			}; Kind = 'read' }
		[PSCustomObject]@{ Key = '8'; Label = 'Analytics (einzeln)'; Function = 'Get-NextDnsAnalytics'; Parameters = {
				$dim = Read-Host 'Dimension (status/domains/reasons/ips/devices/protocols/queryTypes/ipVersions/dnssec/encryption/destinations)'
				$type = $null
				if ($dim -eq 'destinations') {
					$type = Read-NextDnsChoice -Prompt 'Type' -Valid @('countries', 'gafam')
				}
				@{ Dimension = $dim; Type = $type }
			}; Kind = 'read' }
		[PSCustomObject]@{ Key = '9'; Label = 'Alle Analytics'; Function = 'Get-NextDnsAllAnalytics'; Parameters = $null; Kind = 'read' }
		[PSCustomObject]@{ Key = 'A'; Label = 'Verbindung testen'; Function = 'Test-NextDnsConnection'; Parameters = $null; Kind = 'read' }
		[PSCustomObject]@{ Key = 'B'; Label = 'Logs als JSON exportieren'; Function = 'Export-NextDnsLogsJson'; Parameters = {
				$limit = Read-NextDnsInt -Prompt 'Anzahl (Standard 100)' -Default 100
				@{ Limit = $limit }
			}; Kind = 'write' }
		[PSCustomObject]@{ Key = 'C'; Label = 'FULL REPORT'; Function = 'Export-NextDnsFullReport'; Parameters = {
				$withoutLogs = (Read-Host 'Ohne Logs (schneller)? (j/N)') -match '^[jJyY]'
				@{ WithoutLogs = $withoutLogs }
			}; Kind = 'write' }
		[PSCustomObject]@{ Key = 'D'; Label = 'Domain zur Denylist hinzufuegen'; Function = 'Add-NextDnsDenylistEntry'; Parameters = {
				$d = Read-Host 'Domain(s), Komma getrennt'
				@{ Domains = ($d -split ',' | ForEach-Object { $_.Trim() }) }
			}; Kind = 'write' }
		[PSCustomObject]@{ Key = 'E'; Label = 'Domain aus Denylist entfernen'; Function = 'Remove-NextDnsDenylistEntry'; Parameters = {
				$d = Read-Host 'Domain(s), Komma getrennt'
				@{ Domains = ($d -split ',' | ForEach-Object { $_.Trim() }) }
			}; Kind = 'write' }
		[PSCustomObject]@{ Key = 'F'; Label = 'Domain zur Allowlist hinzufuegen'; Function = 'Add-NextDnsAllowlistEntry'; Parameters = {
				$d = Read-Host 'Domain(s), Komma getrennt'
				@{ Domains = ($d -split ',' | ForEach-Object { $_.Trim() }) }
			}; Kind = 'write' }
		[PSCustomObject]@{ Key = 'G'; Label = 'Profil wechseln'; Function = 'Set-NextDnsProfileId'; Parameters = {
				@{ ProfileId = (Read-Host 'Profil-ID (6 Zeichen)').Trim() }
			}; Kind = 'config' }
		[PSCustomObject]@{ Key = 'H'; Label = 'Log-Verlauf LOESCHEN'; Function = 'Clear-NextDnsLogs'; Parameters = $null; Kind = 'write' }
	)
}

function Read-NextDnsInt {
	<#
	.SYNOPSIS
		Liest eine positive Ganzzahl; leere Eingabe = Default.
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)][string]$Prompt,
		[int]$Default = 0
	)
	while ($true) {
		$val = Read-Host $Prompt
		if ([string]::IsNullOrWhiteSpace($val)) { return $Default }
		$parsed = 0
		if ([int]::TryParse($val, [ref]$parsed) -and $parsed -ge 0) { return $parsed }
		Write-Host '  Ungueltige Zahl. Bitte erneut eingeben.' -ForegroundColor Red
	}
}

function Read-NextDnsChoice {
	<#
	.SYNOPSIS
		Liest einen Wert aus einer erlaubten Liste; leere Eingabe = erstes
		Element (typischerweise der Default).
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)][string]$Prompt,
		[Parameter(Mandatory)][string[]]$Valid
	)
	while ($true) {
		$val = (Read-Host "$Prompt [$($Valid -join '/')]").Trim()
		if ([string]::IsNullOrWhiteSpace($val) -and '' -in $Valid) { return '' }
		if ($val -in $Valid) { return $val }
		Write-Host "  Erlaubt: $($Valid -join ', ')" -ForegroundColor Red
	}
}

function Show-NextDnsResult {
	<#
	.SYNOPSIS
		Gibt ein Result-/AllPages-Objekt menuegerecht aus (einzige
		Konsolausgabe-Schicht; vom Menu- und CLI-Modus geteilt).
	#>
	[CmdletBinding()]
	param(
		[AllowNull()][object]$Result,
		[string]$Title
	)
	if ($Title) { Write-Host "`n=== $Title ===" -ForegroundColor Cyan }
	$icons = Get-NextDnsIcons

	if ($null -eq $Result) {
		Write-Host ("  {0} keine Daten" -f $icons.Info) -ForegroundColor DarkYellow
		return
	}

	# AllPages-Objekt (Entries/Pages/Error)
	if ($Result.PSObject.Properties['Entries']) {
		if ($Result.Error) {
			Write-Host ("  {0} FEHLER: {1}" -f $icons.Cross, $Result.Error) -ForegroundColor Red
			return
		}
		Write-Host ("  {0} Eintraege auf {1} Seite(n)" -f $Result.Entries.Count, $Result.Pages) -ForegroundColor Green
		foreach ($entry in $Result.Entries) {
			if ($entry -and $entry.PSObject.Properties['id']) { Write-Host "  - $($entry.id)" }
			else { Write-Host "  - $($entry | ConvertTo-Json -Compress -Depth 3)" }
		}
		return
	}

	# Result-Objekt (Ok/Status/Data/Error)
	if ($Result.PSObject.Properties['Ok']) {
		if (-not $Result.Ok) {
			Write-Host "  x FEHLER: $($Result.Error)" -ForegroundColor Red
			return
		}
		if ($null -ne $Result.Data -and @($Result.Data).Count -gt 0) {
			Write-Host (($Result.Data | ConvertTo-Json -Depth 10))
		} else {
			Write-Host ("  {0} keine Daten" -f $icons.Info) -ForegroundColor DarkYellow
		}
		return
	}

	# Hashtabelle (Get-NextDnsSettings: section -> Result)
	if ($Result -is [System.Collections.IDictionary]) {
		foreach ($key in $Result.Keys) {
			Write-Host "`n--- $key ---" -ForegroundColor Yellow
			Show-NextDnsResult -Result $Result[$key]
		}
		return
	}

	# Roher Rückgabewert (z. B. Pfad-String der Exporte)
	Write-Host ("  {0}" -f $Result) -ForegroundColor Green
}

function Invoke-NextDnsMenuAction {
	<#
	.SYNOPSIS
		Fuehrt eine Tabellen-Zeile aus: Parameter sammeln (Prompt-Plan oder
		vorgegebene Hashtabelle), Funktion aufrufen, Result ausgeben.
		Wird von Menue- UND CLI-Modus benutzt (kein Duplikat-Code).
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)][object]$Entry,
		[hashtable]$SuppliedParameters
	)
	$fn = Get-Command $Entry.Function -ErrorAction SilentlyContinue
	if (-not $fn) {
		Write-Host "  x Funktion nicht gefunden: $($Entry.Function)" -ForegroundColor Red
		return
	}

	$callParams = @{}
	if ($Entry.Parameters) {
		# Interaktiver Prompt-Plan
		$plan = & $Entry.Parameters
		if ($plan) { $callParams = $plan }
	} elseif ($SuppliedParameters) {
		$callParams = $SuppliedParameters
	}

	try {
		$result = & $Entry.Function @callParams
		Show-NextDnsResult -Result $result -Title $Entry.Label
	} catch {
		Write-Host "  x FEHLER: $($_.Exception.Message)" -ForegroundColor Red
	}
}

function Show-NextDnsMenu {
	<#
	.SYNOPSIS
		Interaktive Hauptschleife. Faellt in Non-Interactive-Hosts auf
		Exit zurueck (keine Endlosschleife, PLAN Befund 9).
	#>
	[CmdletBinding()]
	param()

	# Config + Auth sicherstellen (bricht mit klarer Meldung ab, wenn Secrets fehlen)
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

	Initialize-NextDnsIcons
	$icons = Get-NextDnsIcons
	$table = Get-NextDnsMenuTable
	$hostInteractive = -not [Console]::IsOutputRedirected -and [Environment]::UserInteractive

	while ($true) {
		try { Clear-Host } catch { }
		Write-Host '============================================================' -ForegroundColor Cyan
		Write-Host ("  {0} NextDNS Manager (Modul-Version)" -f $icons.Header) -ForegroundColor Cyan
		if ($icons.Mode -eq 'nerd') {
			Write-Host ("  Font: $($icons.Font)") -ForegroundColor DarkGray
		}
		Write-Host '============================================================' -ForegroundColor Cyan
		foreach ($entry in $table) {
			$icon = if ($entry.Kind -eq 'write') { $icons.Write } else { $icons.Read }
			$color = if ($entry.Kind -eq 'write') { 'Yellow' } else { 'White' }
			Write-Host ("  {0}. {1} {2}" -f $entry.Key, $icon, $entry.Label) -ForegroundColor $color
		}
		Write-Host '  0. Beenden' -ForegroundColor Cyan
		Write-Host '============================================================' -ForegroundColor Cyan

		if (-not $hostInteractive) {
			Write-Host 'x Kein interaktiver Host - Menue-Modus nicht verfuegbar. Nutze: run.ps1 -Action <name>' -ForegroundColor Red
			exit 2
		}

		$choice = ''
		try {
			$choice = (Read-Host "`nAuswahl").ToUpper().Trim()
		} catch {
			Write-Host "x Eingabe nicht moeglich: $($_.Exception.Message)" -ForegroundColor Red
			exit 2
		}

		if ($choice -eq '0') {
			Write-Host "`nAuf Wiedersehen!" -ForegroundColor Cyan
			break
		}

		$entry = $table | Where-Object { $_.Key -eq $choice } | Select-Object -First 1
		if ($entry) {
			Invoke-NextDnsMenuAction -Entry $entry
			if ($hostInteractive) {
				Write-Host "`n[Beliebige Taste fuer das Menue]" -ForegroundColor DarkGray
				try { $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') } catch { Start-Sleep -Milliseconds 800 }
			}
		} else {
			Write-Host "`nUngueltige Auswahl!" -ForegroundColor Red
		}
	}
}
