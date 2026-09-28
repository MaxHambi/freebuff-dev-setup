# 20-Auth.ps1 - Secret-Handling via SecretManagement/SecretStore.
#
# Konvention: Connect-NextDnsApi ohne Parameter laedt API_KEY/PROFILE_KEY
# aus dem Default-Vault. -ApiKey/-ProfileId erlauben Injektion (Tests,
# CLI-Uebergabe); dann wird kein SecretManagement angefasst.

function Connect-NextDnsApi {
	<#
	.SYNOPSIS
		Laedt ApiKey/ProfileId in den Konfig-Satz (Vault oder Injektion).
	#>
	[CmdletBinding()]
	param(
		[string]$ApiKeyName = 'API_KEY',
		[string]$ProfileKeyName = 'PROFILE_KEY',
		[string]$VaultName,
		# Test-/CLI-Injektion: wenn gesetzt, wird der Vault NICHT angefragt
		[string]$ApiKey,
		[string]$ProfileId
	)

	$cfg = Get-NextDnsConfig

	if (-not [string]::IsNullOrWhiteSpace($ApiKey)) {
		$cfg.ApiKey = $ApiKey.Trim()
	} else {
		$loadParams = @{ Name = $ApiKeyName; AsPlainText = $true; ErrorAction = 'Stop' }
		if ($VaultName) { $loadParams.Vault = $VaultName }
		$raw = Get-Secret @loadParams
		$cfg.ApiKey = ("$raw").Trim()
	}

	if (-not [string]::IsNullOrWhiteSpace($ProfileId)) {
		$cfg.ProfileId = $ProfileId.Trim()
	} else {
		$loadParams = @{ Name = $ProfileKeyName; AsPlainText = $true; ErrorAction = 'Stop' }
		if ($VaultName) { $loadParams.Vault = $VaultName }
		$raw = Get-Secret @loadParams
		$cfg.ProfileId = ("$raw").Trim()
	}

	Assert-NextDnsConfigReady
	return $cfg
}
