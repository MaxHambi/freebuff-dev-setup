@{
	# PSA-Regelsatz fuer die Test-/Smoke-Schicht (Issue #42).
	#
	# Erbt die Quelleinstellungen (ExcludeRules + Rules) und ergaenzt
	# test-spezifische Ausnahmen mit Begruendung:
	#
	# - PSReviewUnusedParameter: Die Mock-Handler in Tests/Smokes deklarieren
	#   die Delegate-Signatur KOMPLETT (param($Uri, $Method, $Headers,
	#   $JsonBody, $TimeoutSec)), auch wenn ein konkreter Handler nur Teile
	#   nutzt. Das ist ein bewusster Vertrag (jeder Handler ist
	#   signature-kompatibel), kein toter Code.
	#
	# Quellpfad der Basis-Regeln: ../PSScriptAnalyzerSettings.psd1
	# (PSA unterstuetzt kein Inherits - die Basisliste wird hier gepflegt;
	# Aenderungen an der Basis bitte synchron ziehen.)
	ExcludeRules = @(
		'PSAvoidUsingWriteHost',
		'PSAvoidUsingPlainTextForPassword',
		'PSUseShouldProcessForStateChangingFunctions',
		'PSUseBOMForUnicodeEncodedFile',
		'PSUseOutputTypeCorrectly',
		'PSUseSingularNouns',
		'PSAvoidUsingEmptyCatchBlock',
		'PSReviewUnusedParameter'
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
			AllowList = @()
		}
	}
}
