#Requires -Version 7.4
# setup.ps1 - Onboarding-Assistent fuer den NextDNS-Manager.
#
# Prueft Modul-Prereqs (SecretManagement/SecretStore), Vault-Registration
# und die beiden Secrets. Legt auf Wunsch den Vault an. Setzt KEINE Secrets
# selbst - das bleibt eine bewusste Operator-Entscheidung (keine Keys auf
# der Kommandozeile).
#
# Exit-Codes: 0 = bereit (oder nur Hinweise), 1 = harte Prereq-Fehler.

[CmdletBinding()]
param(
	# Geheimnamen im Vault (Default wie im Alt-Script)
	[string]$ApiKeyName = 'API_KEY',
	[string]$ProfileKeyName = 'PROFILE_KEY',
	# Nur pruefen, nichts anlegen
	[switch]$CheckOnly
)

$ErrorActionPreference = 'Stop'

function Test-ModuleAvailable {
	param([string]$Name)
	return [bool](Get-Module -ListAvailable -Name $Name)
}

$problems = @()
$notes = @()

Write-Host '===== NextDNS-Manager Setup =====' -ForegroundColor Cyan

# 1) SecretManagement/SecretStore
foreach ($mod in @('Microsoft.PowerShell.SecretManagement', 'Microsoft.PowerShell.SecretStore')) {
	if (Test-ModuleAvailable $mod) {
		Write-Host "OK   Modul vorhanden: $mod" -ForegroundColor Green
	} else {
		$problems += "Modul fehlt: $mod (Install-Module $mod -Scope CurrentUser)"
		Write-Host "FEHLT Modul: $mod" -ForegroundColor Red
	}
}

# 2) Vault-Registration
$defaultVault = $null
if (-not $problems) {
	Import-Module Microsoft.PowerShell.SecretManagement -ErrorAction Stop
	$defaultVault = (Get-SecretVault | Where-Object { $_.IsDefault } | Select-Object -First 1)
	if ($defaultVault) {
		Write-Host ("OK   Default-Vault: {0} ({1})" -f $defaultVault.Name, $defaultVault.ModuleName) -ForegroundColor Green
	} elseif ($CheckOnly) {
		$problems += 'Kein Default-Vault registriert (Register-SecretVault -Name MyVault -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault)'
		Write-Host 'FEHLT Default-Vault (CheckOnly: wird nicht angelegt)' -ForegroundColor Red
	} else {
		Write-Host '...  Kein Default-Vault - registriere MyVault (SecretStore) ...' -ForegroundColor Yellow
		Register-SecretVault -Name 'MyVault' -ModuleName 'Microsoft.PowerShell.SecretStore' -DefaultVault
		Write-Host 'OK   Vault MyVault registriert' -ForegroundColor Green
	}
}

# 3) Secrets
if (-not $problems) {
	foreach ($pair in @(
			@{ Name = $ApiKeyName; Hint = 'NextDNS API-Key (my.nextdns.io/account, unten)' },
			@{ Name = $ProfileKeyName; Hint = 'NextDNS Profil-ID (6 Zeichen, my.nextdns.io)' }
		)) {
		$secret = Get-Secret -Name $pair.Name -ErrorAction SilentlyContinue
		if ($secret) {
			Write-Host ("OK   Secret vorhanden: {0}" -f $pair.Name) -ForegroundColor Green
		} else {
			$notes += "Secret fehlt: $($pair.Name) - $($pair.Hint)"
			Write-Host ("FEHLT Secret: {0}" -f $pair.Name) -ForegroundColor Yellow
		}
	}
}

if ($notes) {
	Write-Host ''
	Write-Host 'Hinweise:' -ForegroundColor Yellow
	foreach ($n in $notes) {
		Write-Host "  - $n" -ForegroundColor Yellow
	}
	Write-Host ''
	Write-Host 'Secrets setzen (Wert wird interaktiv abgefragt, nicht per Kommandozeile):' -ForegroundColor Yellow
	Write-Host "  Set-Secret -Name $ApiKeyName" -ForegroundColor Yellow
	Write-Host "  Set-Secret -Name $ProfileKeyName" -ForegroundColor Yellow
}

if ($problems) {
	Write-Host ''
	Write-Host 'Setup unvollstaendig:' -ForegroundColor Red
	foreach ($p in $problems) { Write-Host "  - $p" -ForegroundColor Red }
	exit 1
}

Write-Host ''
Write-Host 'Setup bereit. Start mit: pwsh -File run.ps1' -ForegroundColor Green
exit 0
