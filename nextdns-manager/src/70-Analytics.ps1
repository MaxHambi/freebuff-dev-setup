# 70-Analytics.ps1 - Analytics mit Dimensions-Registry.
#
# Regime laut API-Doku (docs/nextdns-api.md):
#   - reasons: KEIN type-Parameter (historisch: type= auf reasons ->
#     HTTP 400 'extraneous'; PLAN Befund 2 korrigiert den Alt-Kommentar)
#   - destinations: type PFLICHT (countries|gafam)
#   - domains: optionale Extras status/root
#   - limit: 1..500 (Default 10)

function Get-NextDnsAnalyticsDimensionSpec {
	<#
	.SYNOPSIS
		Registry: erlaubte Parameter je Dimension (pure, testbar).
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)][string]$Dimension,
		[string]$Type,
		[switch]$Status,
		[switch]$Root
	)

	$cfg = Get-NextDnsConfig
	$dim = $Dimension.Trim()

	if ($dim -in $cfg.NoTypeDims) {
		# reasons & Co: type wird bewusst NICHT gesetzt (Befund 2)
		$type = $null
	}

	if ($dim -in $cfg.TypedAnalyticsDims) {
		if (-not $type) { $type = 'countries' }   # destinations ohne type -> Default
		if ($type -notin $cfg.ValidTypedValues) {
			throw "Dimension '$dim' erfordert type aus [$($cfg.ValidTypedValues -join ', ')], bekommen: '$type'"
		}
	}

	$params = [ordered]@{}
	if ($type) { $params['type'] = $type }
	if ($Status -and $dim -eq 'domains') { $params['status'] = 'blocked' }   # caller setzt konkreten Wert unten
	if ($Root -and $dim -eq 'domains') { $params['root'] = 'true' }

	return [PSCustomObject]@{
		Dimension = $dim
		Params = $params
		AllowsType = ($dim -notin $cfg.NoTypeDims)
	}
}

function Get-NextDnsAnalyticsEndpoint {
	<#
	.SYNOPSIS
		Baut den Analytics-Endpoint (pure, testbar). Unterstuetzt ;series.
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)][string]$Dimension,
		[string]$Type,
		[ValidateSet('', 'default', 'blocked', 'allowed')][string]$Status = '',
		[switch]$Root,
		[switch]$Series,
		[int]$Limit = 0,
		[string]$From,
		[string]$To,
		[string]$Device
	)

	$cfg = Get-NextDnsConfig
	$dim = $Dimension.Trim()
	if ($dim -in $cfg.NoTypeDims) { $Type = $null }

	if ($dim -in $cfg.TypedAnalyticsDims) {
		if (-not $Type) { $Type = 'countries' }
		if ($Type -notin $cfg.ValidTypedValues) {
			throw "Dimension '$dim' erfordert type aus [$($cfg.ValidTypedValues -join ', ')], bekommen: '$Type'"
		}
	}

	$path = "/profiles/$((Get-NextDnsConfig).ProfileId)/analytics/$dim"
	if ($Series) { $path += ';series' }

	$parts = @()
	if ($dim -in $cfg.TypedAnalyticsDims) { $parts += "type=$Type" }
	if ($Status -and $dim -eq 'domains') { $parts += "status=$Status" }
	if ($Root -and $dim -eq 'domains') { $parts += 'root=true' }

	$effectiveLimit = if ($Limit -gt 0) { $Limit } else { (Get-NextDnsConfig).DefaultAnalyticsLimit }
	$effectiveLimit = Get-NextDnsClampedLimit -Limit $effectiveLimit -Min 1 -Max (Get-NextDnsConfig).AnalyticsMaxLimit
	$parts += "limit=$effectiveLimit"

	if ($From) { $parts += "from=$([System.Uri]::EscapeDataString($From))" }
	if ($To) { $parts += "to=$([System.Uri]::EscapeDataString($To))" }
	if ($Device) { $parts += "device=$([System.Uri]::EscapeDataString($Device))" }

	# Konkatenation statt "$path?...": ab PS 7.2 gehoert '?' bei "$var?" zum
	# Variablennamen ($path? waere eine leere Variable namens 'path?').
	return ($path + '?' + ($parts -join '&'))
}

function Get-NextDnsAnalytics {
	<#
	.SYNOPSIS
		Ruft eine Analytics-Dimension ab (validiert das Dimensions-Regime).
		Profil-Wechsel ueber Set-NextDnsProfileId (Config ist die Quelle).
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)][string]$Dimension,
		[string]$Type,
		[ValidateSet('', 'default', 'blocked', 'allowed')][string]$Status = '',
		[switch]$Root,
		[switch]$Series,
		[int]$Limit = 0,
		[string]$From,
		[string]$To,
		[string]$Device
	)
	Assert-NextDnsConfigReady

	$ep = Get-NextDnsAnalyticsEndpoint -Dimension $Dimension -Type $Type -Status $Status -Root:$Root -Series:$Series -Limit $Limit -From $From -To $To -Device $Device
	return (Invoke-NextDnsApi -Method 'GET' -Endpoint $ep)
}

function Get-NextDnsAllAnalytics {
	<#
	.SYNOPSIS
		Ruft alle Dimensionen laut Config-Registry ab (Simple + Typed).
	#>
	[CmdletBinding()]
	param(
		[switch]$Series,
		[int]$Limit = 0
	)
	$results = [System.Collections.Generic.List[object]]::new()
	$cfg = Get-NextDnsConfig

	foreach ($dim in $cfg.SimpleAnalyticsDims) {
		$r = Invoke-NextDnsApi -Method 'GET' -Endpoint (Get-NextDnsAnalyticsEndpoint -Dimension $dim -Limit $Limit -Series:$Series)
		[void]$results.Add([PSCustomObject]@{ Name = $dim; Result = $r })
	}
	foreach ($dim in $cfg.TypedAnalyticsDims) {
		foreach ($t in $cfg.ValidTypedValues) {
			$r = Invoke-NextDnsApi -Method 'GET' -Endpoint (Get-NextDnsAnalyticsEndpoint -Dimension $dim -Type $t -Limit $Limit -Series:$Series)
			[void]$results.Add([PSCustomObject]@{ Name = "$dim($t)"; Result = $r })
		}
	}
	return $results
}
