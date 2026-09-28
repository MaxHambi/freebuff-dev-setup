# 10-Config.ps1 - typisierter Konfig-Satz fuer den NextDNS-Manager.
# Alle Werte sind immutable-by-convention (nach Initialize nur lesen).

# Module-lokale Konfig; Initialize-NextDnsConfig setzt sie neu.
$script:NextDnsConfig = $null

function Initialize-NextDnsConfig {
	<#
	.SYNOPSIS
		Erstellt den module-lokalen Konfig-Satz. Ohne Parameter wird die
		Default-Konfig erzeugt; Parameter erlauben gezielte Overrides
		(z. B. fuer Tests oder einen Profil-Wechsel).
	#>
	[CmdletBinding()]
	param(
		[string]$BaseUrl = 'https://api.nextdns.io',
		[int]$DefaultLogLimit = 100,
		[int]$DefaultAnalyticsLimit = 10,
		[int]$LogsPageLimit = 1000,
		[int]$AnalyticsMaxLimit = 500,
		[string[]]$SettingsSections = @(
			'settings', 'privacy', 'privacy/blocklists', 'privacy/natives',
			'security', 'parentalControl'
		),
		[string[]]$SimpleAnalyticsDims = @(
			'status', 'domains', 'reasons', 'ips', 'devices', 'protocols',
			'queryTypes', 'ipVersions', 'dnssec', 'encryption'
		),
		[string[]]$TypedAnalyticsDims = @('destinations'),
		[string[]]$ValidTypedValues = @('countries', 'gafam'),
		# Dimensions, denen NIE ein type-Parameter gehaengt werden darf
		# (historisch: type= auf reasons -> HTTP 400 'extraneous').
		[string[]]$NoTypeDims = @('reasons'),
		[string]$ProfileId = '',
		[string]$ApiKey = ''
	)

	$script:NextDnsConfig = [PSCustomObject]@{
		BaseUrl = $BaseUrl
		DefaultLogLimit = $DefaultLogLimit
		DefaultAnalyticsLimit = $DefaultAnalyticsLimit
		LogsPageLimit = $LogsPageLimit
		AnalyticsMaxLimit = $AnalyticsMaxLimit
		SettingsSections = $SettingsSections
		SimpleAnalyticsDims = $SimpleAnalyticsDims
		TypedAnalyticsDims = $TypedAnalyticsDims
		ValidTypedValues = $ValidTypedValues
		NoTypeDims = $NoTypeDims
		ProfileId = $ProfileId
		ApiKey = $ApiKey
	}

	return $script:NextDnsConfig
}

function Get-NextDnsConfig {
	<#
	.SYNOPSIS
		Liefert den aktuellen Konfig-Satz (lazy Default-Initialisierung).
	#>
	[CmdletBinding()]
	param()
	if (-not $script:NextDnsConfig) {
		$null = Initialize-NextDnsConfig
	}
	return $script:NextDnsConfig
}

function Set-NextDnsProfileId {
	<#
	.SYNOPSIS
		Profil-Wechsel: setzt die aktive Profil-ID im Konfig-Satz.
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)]
		[ValidatePattern('^[a-zA-Z0-9]{6}$')]
		[string]$ProfileId
	)
	$cfg = Get-NextDnsConfig
	$cfg.ProfileId = $ProfileId
}

function Test-NextDnsConfigReady {
	<#
	.SYNOPSIS
		Wahr, wenn BaseUrl, ApiKey und ProfileId gesetzt sind.
	#>
	[CmdletBinding()]
	param()
	$cfg = Get-NextDnsConfig
	return -not [string]::IsNullOrWhiteSpace($cfg.BaseUrl) -and
	-not [string]::IsNullOrWhiteSpace($cfg.ApiKey) -and
	-not [string]::IsNullOrWhiteSpace($cfg.ProfileId)
}

function Assert-NextDnsConfigReady {
	<#
	.SYNOPSIS
		Wirft, wenn die Konfig nicht bereit ist (fehlender ApiKey/ProfileId).
	#>
	[CmdletBinding()]
	param()
	if (-not (Test-NextDnsConfigReady)) {
		$cfg = Get-NextDnsConfig
		$missing = @()
		if ([string]::IsNullOrWhiteSpace($cfg.ApiKey)) { $missing += 'ApiKey (SecretManagement oder -ApiKey)' }
		if ([string]::IsNullOrWhiteSpace($cfg.ProfileId)) { $missing += 'ProfileId (SecretManagement oder -ProfileId)' }
		throw "NextDNS-Konfig unvollstaendig: $($missing -join ', ')"
	}
}
