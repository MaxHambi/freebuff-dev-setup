# 60-Read.ps1 - Read-Funktionen (Profil, Settings, Listen, Logs).
#
# Konvention: Alle Funktionen liefern das Result-Objekt aus
# Resolve-NextDnsApiResult (Ok/Status/Data/Meta/Error) bzw. bei
# Pagination das AllPages-Objekt (Entries/Pages/Error/Truncated).
# Konsolenausgabe macht ausschliesslich Show-NextDnsResult (Menu-Layer).

function Get-NextDnsProfiles {
	<#
	.SYNOPSIS
		Listet alle Profile des Accounts (Basis fuer Profil-Wechsel).
	#>
	[CmdletBinding()]
	param()
	Assert-NextDnsConfigReady
	return (Invoke-NextDnsApi -Method 'GET' -Endpoint '/profiles')
}

function Get-NextDnsProfile {
	<#
	.SYNOPSIS
		Liefert das aktive Profil (oder -ProfileId). Auch via Pipeline.
	#>
	[CmdletBinding()]
	param([string]$ProfileId)
	if (-not $ProfileId) { $ProfileId = (Get-NextDnsConfig).ProfileId }
	Assert-NextDnsConfigReady
	return (Invoke-NextDnsApi -Method 'GET' -Endpoint "/profiles/$ProfileId")
}

function Get-NextDnsSettings {
	<#
	.SYNOPSIS
		Liefert die Settings-Sektionen des Profils (Config: SettingsSections).
	#>
	[CmdletBinding()]
	param([string]$ProfileId)
	if (-not $ProfileId) { $ProfileId = (Get-NextDnsConfig).ProfileId }
	Assert-NextDnsConfigReady

	$sections = @{}
	foreach ($section in (Get-NextDnsConfig).SettingsSections) {
		$r = Invoke-NextDnsApi -Method 'GET' -Endpoint "/profiles/$ProfileId/$section"
		$sections[$section] = $r
	}
	return $sections
}

function Get-NextDnsBlocklists {
	<#
	.SYNOPSIS
		Liefert die Blocklisten des Profils.
	#>
	[CmdletBinding()]
	param([string]$ProfileId)
	if (-not $ProfileId) { $ProfileId = (Get-NextDnsConfig).ProfileId }
	return (Invoke-NextDnsApi -Method 'GET' -Endpoint "/profiles/$ProfileId/privacy/blocklists")
}

function Get-NextDnsDenylist {
	<#
	.SYNOPSIS
		Liefert alle Denylist-Eintraege inkl. Folgeseiten.
	#>
	[CmdletBinding()]
	param(
		[string]$ProfileId,
		[int]$MaxEntries = 0
	)
	if (-not $ProfileId) { $ProfileId = (Get-NextDnsConfig).ProfileId }
	$limit = Get-NextDnsClampedLimit -Limit (Get-NextDnsConfig).LogsPageLimit -Min 10 -Max 1000
	return (Get-NextDnsAllPages -Endpoint "/profiles/$ProfileId/denylist" -PageLimit $limit -MaxEntries $MaxEntries)
}

function Get-NextDnsAllowlist {
	<#
	.SYNOPSIS
		Liefert alle Allowlist-Eintraege inkl. Folgeseiten.
	#>
	[CmdletBinding()]
	param(
		[string]$ProfileId,
		[int]$MaxEntries = 0
	)
	if (-not $ProfileId) { $ProfileId = (Get-NextDnsConfig).ProfileId }
	$limit = Get-NextDnsClampedLimit -Limit (Get-NextDnsConfig).LogsPageLimit -Min 10 -Max 1000
	return (Get-NextDnsAllPages -Endpoint "/profiles/$ProfileId/allowlist" -PageLimit $limit -MaxEntries $MaxEntries)
}

function Get-NextDnsLogs {
	<#
	.SYNOPSIS
		Liefert DNS-Logs mit vollem Filter-Satz (Doku: from/to/sort/limit/
		cursor/device/status/search/raw).
	#>
	[CmdletBinding()]
	param(
		[int]$Limit = 0,                    # 0 -> Config-Default (100)
		[ValidateSet('default', 'error', 'blocked', 'allowed', '')][string]$Status = '',
		[string]$Search,
		[string]$Device,
		[string]$From,                      # Date: ISO, Unix, relativ (-6h), 2021-03-15
		[string]$To,
		[ValidateSet('asc', 'desc', '')][string]$Sort = '',
		[switch]$Raw,                       # raw=1: ALLE DNS-Queries (auch Rauschen)
		[string]$ProfileId
	)
	if (-not $ProfileId) { $ProfileId = (Get-NextDnsConfig).ProfileId }

	$cfg = Get-NextDnsConfig
	$effectiveLimit = if ($Limit -gt 0) { $Limit } else { $cfg.DefaultLogLimit }
	$effectiveLimit = Get-NextDnsClampedLimit -Limit $effectiveLimit -Min 10 -Max 1000

	$parts = @("limit=$effectiveLimit")
	if ($Status) { $parts += "status=$Status" }
	if ($Search) { $parts += "search=$([System.Uri]::EscapeDataString($Search))" }
	if ($Device) { $parts += "device=$([System.Uri]::EscapeDataString($Device))" }
	if ($From) { $parts += "from=$([System.Uri]::EscapeDataString($From))" }
	if ($To) { $parts += "to=$([System.Uri]::EscapeDataString($To))" }
	if ($Sort) { $parts += "sort=$Sort" }
	if ($Raw) { $parts += 'raw=1' }

	$endpoint = "/profiles/$ProfileId/logs?$($parts -join '&')"
	return (Invoke-NextDnsApi -Method 'GET' -Endpoint $endpoint)
}
