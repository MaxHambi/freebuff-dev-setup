# 80-Write.ps1 - Write-Funktionen mit ShouldProcess-Schutz.
#
# Alle schreibenden Operationen:
#   - SupportsShouldProcess (-WhatIf macht garantikt KEINEN HTTP-Call,
#     weil ShouldProcess VOR dem Call ausgewertet wird)
#   - errors[]-Pfad aus 30-ErrorHandling wird ausgewertet: eine mit
#     200 OK + errors[] abgelehnte Domain ist ein Fehler, kein Erfolg
#     (PLAN Befund 1/6)
#   - DELETE am Child-Endpoint: /denylist/<id> (erste Key = id)

function Add-NextDnsDenylistEntry {
	<#
	.SYNOPSIS
		Fuegt Domain(s) zur Denylist hinzu. Liefert je Domain ein
		Ergebnis-Objekt { Domain; Ok; Error }.
	#>
	[CmdletBinding(SupportsShouldProcess)]
	param(
		[Parameter(ValueFromPipeline)]
		[AllowEmptyCollection()]
		[AllowNull()]
		[string[]]$Domains,
		[string]$ProfileId
	)
	process {
		if (-not $ProfileId) { $ProfileId = (Get-NextDnsConfig).ProfileId }
		Assert-NextDnsConfigReady
		# Hinweis: [Parameter(Mandatory)] auf string[] lehnt Arrays mit leerem
		# String ab (PS-Quirk) - deshalb Batch-Konvention: leere Eintraege werden
		# als Fehler-Ergebnis gemeldet, nicht abgelehnt.
		if (-not $Domains) {
			[PSCustomObject]@{ Domain = ''; Ok = $false; Error = 'keine Domains uebergeben' }
			return
		}

		foreach ($domain in $Domains) {
			$clean = "$domain".Trim()
			if (-not $clean) {
				[PSCustomObject]@{ Domain = $domain; Ok = $false; Error = 'leerer Eintrag' }
				continue
			}
			if (-not $PSCmdlet.ShouldProcess("Denylist: $clean", 'POST')) {
				[PSCustomObject]@{ Domain = $clean; Ok = $false; Error = 'WhatIf/Confirm abgebrochen' }
				continue
			}
			$r = Invoke-NextDnsApi -Method 'POST' -Endpoint "/profiles/$ProfileId/denylist" -Body @{ id = $clean; active = $true }
			if ($r.Ok) {
				[PSCustomObject]@{ Domain = $clean; Ok = $true; Error = $null }
			} else {
				# errors[]-Pfad: User-Fehler (ungueltige Domain) = Ok=$false
				[PSCustomObject]@{ Domain = $clean; Ok = $false; Error = $r.Error }
			}
		}
	}
}

function Add-NextDnsAllowlistEntry {
	<#
	.SYNOPSIS
		Fuegt Domain(s) zur Allowlist hinzu (siehe Add-NextDnsDenylistEntry).
	#>
	[CmdletBinding(SupportsShouldProcess)]
	param(
		[Parameter(ValueFromPipeline)]
		[AllowEmptyCollection()]
		[AllowNull()]
		[string[]]$Domains,
		[string]$ProfileId
	)
	process {
		if (-not $ProfileId) { $ProfileId = (Get-NextDnsConfig).ProfileId }
		Assert-NextDnsConfigReady
		if (-not $Domains) {
			[PSCustomObject]@{ Domain = ''; Ok = $false; Error = 'keine Domains uebergeben' }
			return
		}

		foreach ($domain in $Domains) {
			$clean = "$domain".Trim()
			if (-not $clean) {
				[PSCustomObject]@{ Domain = $domain; Ok = $false; Error = 'leerer Eintrag' }
				continue
			}
			if (-not $PSCmdlet.ShouldProcess("Allowlist: $clean", 'POST')) {
				[PSCustomObject]@{ Domain = $clean; Ok = $false; Error = 'WhatIf/Confirm abgebrochen' }
				continue
			}
			$r = Invoke-NextDnsApi -Method 'POST' -Endpoint "/profiles/$ProfileId/allowlist" -Body @{ id = $clean; active = $true }
			if ($r.Ok) {
				[PSCustomObject]@{ Domain = $clean; Ok = $true; Error = $null }
			} else {
				[PSCustomObject]@{ Domain = $clean; Ok = $false; Error = $r.Error }
			}
		}
	}
}

function Remove-NextDnsDenylistEntry {
	<#
	.SYNOPSIS
		Entfernt Domain(s) aus der Denylist (DELETE am Child-Endpoint).
	#>
	[CmdletBinding(SupportsShouldProcess)]
	param(
		[Parameter(ValueFromPipeline)]
		[AllowEmptyCollection()]
		[AllowNull()]
		[string[]]$Domains,
		[string]$ProfileId
	)
	process {
		if (-not $ProfileId) { $ProfileId = (Get-NextDnsConfig).ProfileId }
		Assert-NextDnsConfigReady
		if (-not $Domains) {
			[PSCustomObject]@{ Domain = ''; Ok = $false; Error = 'keine Domains uebergeben' }
			return
		}

		foreach ($domain in $Domains) {
			$clean = "$domain".Trim()
			if (-not $clean) {
				[PSCustomObject]@{ Domain = $domain; Ok = $false; Error = 'leerer Eintrag' }
				continue
			}
			if (-not $PSCmdlet.ShouldProcess("Denylist: $clean", 'DELETE')) {
				[PSCustomObject]@{ Domain = $clean; Ok = $false; Error = 'WhatIf/Confirm abgebrochen' }
				continue
			}
			$encoded = [System.Uri]::EscapeDataString($clean)
			$r = Invoke-NextDnsApi -Method 'DELETE' -Endpoint "/profiles/$ProfileId/denylist/$encoded"
			if ($r.Ok) {
				[PSCustomObject]@{ Domain = $clean; Ok = $true; Error = $null }
			} else {
				[PSCustomObject]@{ Domain = $clean; Ok = $false; Error = $r.Error }
			}
		}
	}
}

function Remove-NextDnsAllowlistEntry {
	<#
	.SYNOPSIS
		Entfernt Domain(s) aus der Allowlist (DELETE am Child-Endpoint).
	#>
	[CmdletBinding(SupportsShouldProcess)]
	param(
		[Parameter(ValueFromPipeline)]
		[AllowEmptyCollection()]
		[AllowNull()]
		[string[]]$Domains,
		[string]$ProfileId
	)
	process {
		if (-not $ProfileId) { $ProfileId = (Get-NextDnsConfig).ProfileId }
		Assert-NextDnsConfigReady
		if (-not $Domains) {
			[PSCustomObject]@{ Domain = ''; Ok = $false; Error = 'keine Domains uebergeben' }
			return
		}

		foreach ($domain in $Domains) {
			$clean = "$domain".Trim()
			if (-not $clean) {
				[PSCustomObject]@{ Domain = $domain; Ok = $false; Error = 'leerer Eintrag' }
				continue
			}
			if (-not $PSCmdlet.ShouldProcess("Allowlist: $clean", 'DELETE')) {
				[PSCustomObject]@{ Domain = $clean; Ok = $false; Error = 'WhatIf/Confirm abgebrochen' }
				continue
			}
			$encoded = [System.Uri]::EscapeDataString($clean)
			$r = Invoke-NextDnsApi -Method 'DELETE' -Endpoint "/profiles/$ProfileId/allowlist/$encoded"
			if ($r.Ok) {
				[PSCustomObject]@{ Domain = $clean; Ok = $true; Error = $null }
			} else {
				[PSCustomObject]@{ Domain = $clean; Ok = $false; Error = $r.Error }
			}
		}
	}
}

function Set-NextDnsSettings {
	<#
	.SYNOPSIS
		PATCHT eine Settings-Sektion. Validiert den Pfad gegen die
		bekannten Sektionen (Config) bzw. erlaubt explizit freigegebene
		Sub-Pfade (blockPage, performance, logs, ...).
	#>
	[CmdletBinding(SupportsShouldProcess)]
	param(
		[Parameter(Mandatory)][ValidateSet(
			'settings', 'privacy', 'security', 'parentalControl',
			'settings/logs', 'settings/blockPage', 'settings/performance'
		)][string]$Section,
		[Parameter(Mandatory)][object]$Body,
		[string]$ProfileId
	)
	if (-not $ProfileId) { $ProfileId = (Get-NextDnsConfig).ProfileId }
	Assert-NextDnsConfigReady

	if (-not $PSCmdlet.ShouldProcess("Settings/$Section", 'PATCH')) {
		return [PSCustomObject]@{ Ok = $false; Error = 'WhatIf/Confirm abgebrochen' }
	}
	return (Invoke-NextDnsApi -Method 'PATCH' -Endpoint "/profiles/$ProfileId/$Section" -Body $Body)
}

function Clear-NextDnsLogs {
	<#
	.SYNOPSIS
		Loescht den Log-Verlauf des Profils (DELETE /logs). ConfirmImpact=High:
		ohne -Force wird immer nachgefragt.
	#>
	[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
	param([string]$ProfileId)
	if (-not $ProfileId) { $ProfileId = (Get-NextDnsConfig).ProfileId }
	Assert-NextDnsConfigReady

	$confirmTarget = "Log-Verlauf des Profils $ProfileId"
	if (-not $PSCmdlet.ShouldProcess($confirmTarget, 'DELETE')) {
		return [PSCustomObject]@{ Ok = $false; Error = 'WhatIf/Confirm abgebrochen' }
	}
	return (Invoke-NextDnsApi -Method 'DELETE' -Endpoint "/profiles/$ProfileId/logs")
}
