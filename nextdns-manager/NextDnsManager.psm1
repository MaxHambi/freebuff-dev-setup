# NextDnsManager.psm1 - laedt alle Submodule aus src/ (sortiert, deterministisch).
# Reihenfolge ueber Namenspraefixe steuerbar; aktueles Layout:
#   10-Config.ps1, 20-Auth.ps1, 30-ErrorHandling.ps1, 40-Api.ps1,
#   50-Pagination.ps1, 60-Read.ps1, 70-Analytics.ps1, 80-Write.ps1,
#   90-Report.ps1, 99-Menu.ps1

$script:ModuleRoot = $PSScriptRoot

$srcPath = Join-Path -Path $script:ModuleRoot -ChildPath 'src'
if (Test-Path -LiteralPath $srcPath) {
	Get-ChildItem -Path $srcPath -Filter '*.ps1' -File |
		Sort-Object -Property Name |
		ForEach-Object { . $_.FullName }
}

Export-ModuleMember -Function '*'
