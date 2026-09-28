# NextDnsManager.psm1 - laedt alle Submodule aus src/ (sortiert, deterministisch).
# Reihenfolge ueber Namenspraefixe steuerbar; aktueles Layout:
#   10-Config.ps1, 15-Fonts.ps1, 20-Auth.ps1, 30-ErrorHandling.ps1, 40-Api.ps1,
#   50-Pagination.ps1, 60-Read.ps1, 70-Analytics.ps1, 80-Write.ps1,
#   90-Report.ps1, 99-Menu.ps1

$script:ModuleRoot = $PSScriptRoot

$srcPath = Join-Path -Path $script:ModuleRoot -ChildPath 'src'
if (Test-Path -LiteralPath $srcPath) {
	Get-ChildItem -Path $srcPath -Filter '*.ps1' -File |
		Sort-Object -Property Name |
		ForEach-Object { . $_.FullName }
}

# Explizite Export-Liste (statt '*'): verhindert versehentliche Exporte von
# Implementierungsdetails (z. B. Invoke-NextDnsHttpRequest) und erfuellt
# PSUseToExportFieldsInManifest. Set-NextDnsHttpDelegate ist absichtlich
# oeffentlich: Test-Seam (siehe 40-Api.ps1).
$publicFunctions = @(
	# 10-Config
	'Initialize-NextDnsConfig', 'Get-NextDnsConfig', 'Set-NextDnsProfileId',
	'Test-NextDnsConfigReady', 'Assert-NextDnsConfigReady',
	# 15-Fonts
	'Test-NextDnsNerdFont', 'Initialize-NextDnsIcons', 'Set-NextDnsIconMode',
	'Get-NextDnsIcons', 'Get-NextDnsFontInfo',
	# 20-Auth
	'Connect-NextDnsApi',
	# 30-ErrorHandling
	'Get-NextDnsErrorDetail', 'Resolve-NextDnsApiResult',
	# 40-Api
	'Invoke-NextDnsApi', 'Set-NextDnsHttpDelegate',
	# 50-Pagination
	'Get-NextDnsClampedLimit', 'Get-NextDnsPaginationCursor', 'Get-NextDnsAllPages',
	# 60-Read
	'Get-NextDnsProfiles', 'Get-NextDnsProfile', 'Get-NextDnsSettings',
	'Get-NextDnsBlocklists', 'Get-NextDnsDenylist', 'Get-NextDnsAllowlist',
	'Test-NextDnsConnection', 'Get-NextDnsLogs',
	# 70-Analytics
	'Get-NextDnsAnalyticsDimensionSpec', 'Get-NextDnsAnalyticsEndpoint',
	'Get-NextDnsAnalytics', 'Get-NextDnsAllAnalytics',
	# 80-Write
	'Add-NextDnsDenylistEntry', 'Add-NextDnsAllowlistEntry',
	'Remove-NextDnsDenylistEntry', 'Remove-NextDnsAllowlistEntry',
	'Set-NextDnsSettings', 'Clear-NextDnsLogs',
	# 90-Report
	'New-NextDnsReportFile', 'Write-NextDnsReportSection', 'Add-NextDnsReportResult',
	'Export-NextDnsLogsJson', 'Export-NextDnsFullReport',
	# 99-Menu
	'Get-NextDnsMenuTable', 'Read-NextDnsInt', 'Read-NextDnsChoice',
	'Show-NextDnsResult', 'Invoke-NextDnsMenuAction', 'Show-NextDnsMenu'
)
Export-ModuleMember -Function $publicFunctions
