# 90-Report.ps1 - Export-Funktionen (Full-Report, JSON-Exporte).
#
# Zerlegt nach Skill-Checkliste (Funktionen < 50 Zeilen):
#   New-NextDnsReportSection / Add-NextDnsReportResult (Bausteine),
#   Export-NextDnsFullReport (Orchestrierung), Export-NextDnsLogsJson.

function New-NextDnsReportFile {
	<#
	.SYNOPSIS
		Erstellt Report-Datei + StreamWriter. Liefert @{ Writer; Path }.
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)][string]$Directory,
		[string]$Prefix = 'nextdns-fullreport'
	)
	$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
	$path = Join-Path -Path $Directory -ChildPath "$prefix-$stamp.txt"
	try {
		$writer = [System.IO.StreamWriter]::new($path, $false, [System.Text.Encoding]::UTF8)
	} catch {
		throw "Report-Datei nicht erstellbar: $($_.Exception.Message)"
	}
	return @{ Writer = $writer; Path = $path }
}

function Write-NextDnsReportSection {
	<#
	.SYNOPSIS
		Schreibt eine Sektions-Ueberschrift in den Report.
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)][System.IO.StreamWriter]$Writer,
		[Parameter(Mandatory)][string]$Title,
		[int]$Width = 70
	)
	$line = '=' * $Width
	$Writer.WriteLine('')
	$Writer.WriteLine($line)
	$Writer.WriteLine("  $Title")
	$Writer.WriteLine($line)
}

function Add-NextDnsReportResult {
	<#
	.SYNOPSIS
		Schreibt ein Result-Objekt in den Report; sammelt Fehler in der
		Error-Liste. Liefert $true bei Fehler (fuer den Aufrufer).
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)][System.IO.StreamWriter]$Writer,
		[AllowNull()][object]$Result,
		[AllowNull()][System.Collections.Generic.List[string]]$ErrorList,
		[Parameter(Mandatory)][string]$SectionName,
		[int]$Depth = 10
	)
	# Hinweis: [Parameter(Mandatory)] auf Collections lehnt LEERE Listen ab
	# (PS-Quirk) - deshalb hier der explizite Null-Check.
	if ($null -eq $ErrorList) { throw 'ErrorList erforderlich' }
	if ($Result -and -not $Result.Ok) {
		$line = "FEHLER: $($Result.Error)"
		$Writer.WriteLine($line)
		$ErrorList.Add("$SectionName -> $line")
		return $true
	}
	$data = $null
	if ($Result) { $data = $Result.Data }
	if ($null -ne $data -and @($data).Count -gt 0) {
		$Writer.WriteLine(($data | ConvertTo-Json -Depth $Depth))
	} else {
		$Writer.WriteLine('(keine Daten)')
	}
	return $false
}

function Export-NextDnsLogsJson {
	<#
	.SYNOPSIS
		Exportiert Logs als JSON-Datei. Liefert den Dateipfad.
	#>
	[CmdletBinding()]
	param(
		[int]$Limit = 100,
		[ValidateSet('default', 'error', 'blocked', 'allowed', '')][string]$Status = '',
		[string]$Search,
		[string]$Device,
		[string]$From,
		[string]$To,
		[switch]$Raw,
		[string]$Directory = (Get-Location).Path
	)
	$logs = Get-NextDnsLogs -Limit $Limit -Status $Status -Search $Search -Device $Device -From $From -To $To -Raw:$Raw
	if (-not $logs.Ok) {
		throw "Logs nicht abrufbar: $($logs.Error)"
	}
	$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
	$path = Join-Path -Path $Directory -ChildPath "nextdns-logs-$stamp.json"
	$logs.Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $path -Encoding UTF8
	return $path
}

function Export-NextDnsFullReport {
	<#
	.SYNOPSIS
		Erstellt den Full-Report (Profil, Settings, Listen, Analytics,
		optionale Logs, Fehler-Zusammenfassung). -WithoutLogs spart die
		langsame Log-Pagination ein.
	#>
	[CmdletBinding()]
	param(
		[string]$Directory = (Get-Location).Path,
		[switch]$WithoutLogs,
		[int]$MaxLogPages = 100,
		[int]$MaxLogEntries = 0
	)

	Assert-NextDnsConfigReady
	$report = New-NextDnsReportFile -Directory $Directory
	$writer = $report.Writer
	$errors = [System.Collections.Generic.List[string]]::new()
	$profileId = (Get-NextDnsConfig).ProfileId

	try {
		$masked = (Get-NextDnsConfig).ApiKey
		if ($masked) { $masked = $masked.Substring(0, [Math]::Min(8, $masked.Length)) + '...' } else { $masked = '(leer)' }

		$writer.WriteLine('NEXTDNS FULL REPORT')
		$writer.WriteLine("Erstellt am : $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')")
		$writer.WriteLine("Profil-ID   : $profileId")
		$writer.WriteLine("API-Key     : $masked")

		# Profil
		Write-NextDnsReportSection -Writer $writer -Title 'PROFIL-DETAILS'
		$null = Add-NextDnsReportResult -Writer $writer -Result (Get-NextDnsProfile) -ErrorList $errors -SectionName 'PROFIL' -Depth 20

		# Settings-Sektionen
		Write-NextDnsReportSection -Writer $writer -Title 'EINSTELLUNGEN'
		$settings = Get-NextDnsSettings
		foreach ($key in $settings.Keys) {
			$writer.WriteLine('')
			$writer.WriteLine("--- $key ---")
			$null = Add-NextDnsReportResult -Writer $writer -Result $settings[$key] -ErrorList $errors -SectionName "SETTINGS/$key" -Depth 20
		}

		# Listen
		foreach ($pair in @(
				@{ Title = 'DENYLIST'; Call = { Get-NextDnsDenylist -MaxEntries 2000 } },
				@{ Title = 'ALLOWLIST'; Call = { Get-NextDnsAllowlist -MaxEntries 2000 } }
			)) {
			Write-NextDnsReportSection -Writer $writer -Title $pair.Title
			$res = & $pair.Call
			if ($res.Error) {
				$writer.WriteLine("FEHLER: $($res.Error)")
				$errors.Add("$($pair.Title) -> $($res.Error)")
			} else {
				$writer.WriteLine("Anzahl Eintraege: $($res.Entries.Count)")
				foreach ($entry in $res.Entries) { $writer.WriteLine("  - $($entry.id)") }
			}
		}

		# Analytics (alle Dimensionen)
		Write-NextDnsReportSection -Writer $writer -Title 'ANALYTICS'
		foreach ($item in (Get-NextDnsAllAnalytics)) {
			$writer.WriteLine('')
			$writer.WriteLine("--- $($item.Name) ---")
			$null = Add-NextDnsReportResult -Writer $writer -Result $item.Result -ErrorList $errors -SectionName "ANALYTICS/$($item.Name)" -Depth 20
		}

		# Logs (optional)
		if ($WithoutLogs) {
			Write-NextDnsReportSection -Writer $writer -Title 'DNS-LOGS'
			$writer.WriteLine('(uebersprungen: -WithoutLogs)')
		} else {
			Write-NextDnsReportSection -Writer $writer -Title 'DNS-LOGS (ALLE VERFUEGBAREN)'
			$cfg = Get-NextDnsConfig
			$limit = Get-NextDnsClampedLimit -Limit $cfg.LogsPageLimit -Min 10 -Max 1000
			$all = Get-NextDnsAllPages -Endpoint "/profiles/$profileId/logs" -PageLimit $limit -MaxPages $MaxLogPages -MaxEntries $MaxLogEntries
			if ($all.Error) {
				$writer.WriteLine("HINWEIS: Pagination mit Fehler abgebrochen: $($all.Error)")
				$errors.Add("DNS-LOGS (Pagination) -> $($all.Error)")
			}
			$writer.WriteLine("Anzahl Log-Eintraege: $($all.Entries.Count)")
			foreach ($log in $all.Entries) {
				$reasons = ''
				if ($log.reasons) { $reasons = (($log.reasons | ForEach-Object { $_.id }) -join ',') }
				$writer.WriteLine("[$($log.timestamp)] $($log.status) - $($log.domain)$(if ($reasons) { " ($reasons)" })")
			}
		}

		# Fehler-Zusammenfassung
		Write-NextDnsReportSection -Writer $writer -Title 'FEHLER-ZUSAMMENFASSUNG'
		if ($errors.Count -eq 0) {
			$writer.WriteLine('Keine Fehler waehrend der Report-Erstellung.')
		} else {
			$writer.WriteLine("Anzahl Fehler: $($errors.Count)")
			foreach ($e in $errors) { $writer.WriteLine("  - $e") }
		}
	} finally {
		try { $writer.Flush() } catch { }
		try { $writer.Close() } catch { }
		try { $writer.Dispose() } catch { }
	}

	return [PSCustomObject]@{ Path = $report.Path; Errors = $errors.Count }
}
