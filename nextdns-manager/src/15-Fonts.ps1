# 15-Fonts.ps1 - Nerd-Font-Erkennung fuer die Menue-Darstellung.
#
# Der Operator mag die Gruppen Meslo, JetBrains und Terminess - der Check
# empfiehlt automatisch eine passende, installierte Variante:
#   1. JetBrainsMono NF / Nerd Font  (Primar-Empfehlung des Moduls)
#   2. MesloLGLDZ / MesloLGS NF      (Powerline-10K-Erbe, sehr beliebt)
#   3. Terminess Nerd Font           (kompakt, hohe Zeichen pro Zeile)
# Ohne Treffer: Icons aus, ASCII-Fallback - das Menue bleibt voll funktions-
# faehig (Fail-Safe, kein Absturz ohne Font).

# Module-lokaler Icon-Cache
$script:NextDnsIcons = $null

function Test-NextDnsNerdFont {
	<#
	.SYNOPSIS
		Prueft, ob ein Nerd-Font-Name (Regex, case-insensitive) in der
		Windows-Font-Registry (HKLM/HKCU) installiert ist.
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)][string]$Pattern
	)
	$paths = @(
		'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts',
		'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
	)
	$all = foreach ($p in $paths) {
		if (Test-Path $p) {
			(Get-ItemProperty -Path $p -ErrorAction SilentlyContinue).PSObject.Properties |
				Where-Object { $_.Name -notmatch '^PS' } |
				ForEach-Object { $_.Name }
		}
	}
	foreach ($name in $all) {
		if ("$name" -match $Pattern) { return $true }
	}
	return $false
}

function Initialize-NextDnsIcons {
	<#
	.SYNOPSIS
		Waehlt den Icon-Satz: Nerd-Font-Icons bei erkanntem Font aus der
		JetBrains-/Meslo-/Terminess-Gruppe, sonst ASCII-Fallback.
		Ergebnis landet im module-lokalen Cache (Get-NextDnsIcons).
	#>
	[CmdletBinding()]
	param([switch]$NoIcons)

	if ($NoIcons) { Set-NextDnsIconMode -Mode 'ascii'; return }

	# Reihenfolge = Empfehlungsrang (Operator-Praeferenz: JetBrains, Meslo, Terminess)
	$fontChecks = @(
		@{ Mode = 'nerd'; Pattern = 'JetBrainsMono NF|JetBrainsMono Nerd|JetBrainsMonoNL NF'; Label = 'JetBrainsMono Nerd Font' },
		@{ Mode = 'nerd'; Pattern = 'MesloLGS NF|MesloLGL|MesloLGM|MesloLGLDZ|Meslo NF|Meslo Nerd'; Label = 'Meslo Nerd Font' },
		@{ Mode = 'nerd'; Pattern = 'Terminess Nerd|TerminessTTF Nerd'; Label = 'Terminess Nerd Font' },
		@{ Mode = 'nerd'; Pattern = 'Nerd Font|NerdFont'; Label = 'Nerd Font (generisch)' }
	)

	foreach ($check in $fontChecks) {
		if (Test-NextDnsNerdFont -Pattern $check.Pattern) {
			Set-NextDnsIconMode -Mode $check.Mode -Font $check.Label
			return
		}
	}
	Set-NextDnsIconMode -Mode 'ascii'
}

function Set-NextDnsIconMode {
	<#
	.SYNOPSIS
		Setzt den Icon-Modus (intern): 'nerd' oder 'ascii'.
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)][ValidateSet('nerd', 'ascii')][string]$Mode,
		[string]$Font = ''
	)

	if ($Mode -eq 'nerd') {
		# Nerd-Font-Codepoints (PUA): Dossier, Buch, Getriebe, Liste, Phi/Text,
		# Memo, Beaker, Zap, Play, Papierkorb, Auge, Wechsel, Schere, Tacho, floppy
		$script:NextDnsIcons = [PSCustomObject]@{
			Mode = 'nerd'
			Font = $Font
			Header = "`u{e26c}"          # nf-oct-repo / Dossier-Symbol
			Read = "`u{f022}"           # nf-fa-file_text_o
			Write = "`u{f0c7}"          # nf-fa-save (Warn-Farbe im Menue)
			List = "`u{f0ca}"           # nf-fa-list_ul
			Section = "`u{f02d}"        # nf-fa-book
			Check = "`u{f00c}"          # nf-fa-check
			Cross = "`u{f00d}"          # nf-fa-times
			Warn = "`u{f071}"           # nf-fa-exclamation_triangle
			Info = "`u{f05a}"           # nf-fa-info_circle
			Box = "`u{f4c5}"            # nf-oct-zap-Alternative
			Rocket = "`u{f135}"         # nf-fa-rocket
			Search = "`u{f002}"         # nf-fa-search
			Eye = "`u{f06e}"            # nf-fa-eye
			Trash = "`u{f1f8}"          # nf-fa-trash
			Swap = "`u{f074}"           # nf-fa-exchange
			Chart = "`u{f080}"          # nf-fa-chart_bar
			Shield = "`u{f132}"         # nf-fa-shield
			Floppy = "`u{f0c7}"         # nf-fa-save
		}
	} else {
		$script:NextDnsIcons = [PSCustomObject]@{
			Mode = 'ascii'
			Font = ''
			Header = '#'
			Read = '-'
			Write = '!'
			List = '*'
			Section = '['
			Check = 'OK'
			Cross = 'x'
			Warn = '!!'
			Info = 'i'
			Box = '[]'
			Rocket = '>>'
			Search = '?'
			Eye = 'o'
			Trash = 'del'
			Swap = '<->'
			Chart = '%'
			Shield = '+'
			Floppy = 'save'
		}
	}
}

function Get-NextDnsIcons {
	<#
	.SYNOPSIS
		Liefert den Icon-Satz (lazy ASCII-Default, falls nie initialisiert).
	#>
	[CmdletBinding()]
	param()
	if (-not $script:NextDnsIcons) { Set-NextDnsIconMode -Mode 'ascii' }
	return $script:NextDnsIcons
}

function Get-NextDnsFontInfo {
	<#
	.SYNOPSIS
		Liefert Font-Modus + erkannten Fontnamen (fuer Header/Setup-Hinweis).
	#>
	[CmdletBinding()]
	param()
	$icons = Get-NextDnsIcons
	return [PSCustomObject]@{
		Mode = $icons.Mode
		Font = $icons.Font
		NerdAvailable = ($icons.Mode -eq 'nerd')
	}
}
