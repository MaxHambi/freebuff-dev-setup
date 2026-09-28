@{
	# PSScriptAnalyzer-Regelwerk fuer das Verify-Gate (Issue #42).
	#
	# Bewusste Ausnahmen:
	# - PSAvoidUsingWriteHost: Konsolenausgabe ist hier Produkt (Menue/CLI-Tool),
	#   nicht Fehlerkanal; die Ausgabeschicht liegt bewusst in Show-NextDnsResult.
	# - PSAvoidUsingPlainTextForPassword: es gibt keine Passwort-Parameter;
	#   Secrets laufen ueber SecretManagement (SecureString/PlainText-Objekt im Vault).
	# - PSUseShouldProcessForStateChangingFunctions: Set-NextDnsProfileId /
	#   Initialize-* aendern nur module-lokalen In-Memory-Zustand, keine
	#   externen Systeme.
	# - PSUseOutputTypeCorrectly: PowerShell Streams sind hier by-design gemischt
	#   (Result-Objekte + Konsolenmenue); OutputType-Attribute wuerden falsche
	#   Erwartungen fuer die gemischte Natur wecken.
	# - PSUseSingularNouns: bewusste Sammel-Getter (Get-NextDnsLogs,
	#   Get-NextDnsProfiles, Get-NextDnsAllPages) - fachlich korrekt, da Listen.
	# - PSAvoidUsingEmptyCatchBlock: bewusste Best-Effort-Cleanup-Bloecke
	#   (Headers/Retry-After-Extraktion, Writer-Dispose); kommentiert im Code.
	ExcludeRules = @(
		'PSAvoidUsingWriteHost',
		'PSAvoidUsingPlainTextForPassword',
		'PSUseShouldProcessForStateChangingFunctions',
		'PSUseBOMForUnicodeEncodedFile',
		'PSUseOutputTypeCorrectly',
		'PSUseSingularNouns',
		'PSAvoidUsingEmptyCatchBlock'
	)

	Rules = @{
		PSUseConsistentIndentation = @{
			Enable = $true
			Kind = 'tab'
			PipelineIndentation = 'None'
		}
		PSUseConsistentWhitespace = @{
			Enable = $true
			CheckOpenBrace = $true
			CheckInnerBraces = $false
			CheckPipe = $false
		}
		PSAvoidUsingCmdletAliases = @{
			Enable = $true
			# erlaubte Aliase: keiner ausser explizit gelisteten
			AllowList = @()
		}
	}
}
