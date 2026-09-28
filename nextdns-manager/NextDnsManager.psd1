@{
	# RootModule des NextDNS-Manager-Moduls
	RootModule = 'NextDnsManager.psm1'

	ModuleVersion = '0.1.0'

	GUID = '7f4a2c9e-8b3d-4e1f-9c6a-5d2e8b7a1f34'

	Author = 'MaxHambi'

	CompanyName = 'freebuff-dev-setup'

	Description = 'NextDNS All-in-One Management als PowerShell-Modul: API-Schicht mit Retry/Rate-Limit-Fehlerbehandlung, Read-/Write-Funktionen, Full-Report, CLI- und Menue-Modus. Quelle der Wahrheit fuer die API: docs/nextdns-api.md.'

	PowerShellVersion = '7.4'

	# SecretManagement wird dynamisch in src/Auth.ps1 geladen (kein RequiredModules-Eintrag,
	# damit Import/Tests auch ohne installiertes Modul bzw. auf CI ohne Secrets laufen).
	RequiredModules = @()

	FunctionsToExport = '*'

	VariablesToExport = @()

	AliasesToExport = @()

	PrivateData = @{
		PSData = @{
			Tags = @('NextDNS', 'DNS', 'API', 'Management')
			LicenseUri = 'https://github.com/MaxHambi/freebuff-dev-setup/blob/master/LICENSE'
			ProjectUri = 'https://github.com/MaxHambi/freebuff-dev-setup'
			ReleaseNotes = 'Slice 1 (Issue #37): Modul-Geruest, Setup-Assistent, API-Doku als Repo-Quelle.'
		}
	}
}
