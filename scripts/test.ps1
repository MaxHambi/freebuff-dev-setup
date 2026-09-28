#Requires -Version 5.1
# Test-Einstieg: fuehrt alle repo-seitigen Verifikationen aus.
#
# Schichten (Slice #42, Issue #42):
#   1. Watchdog-DryRun (nur Windows - Get-CimInstance)
#   2. Pester-Suite nextdns-manager/tests/NextDnsManager.Tests.ps1 (gemockt, 0 Live-Calls)
#   3. PSScriptAnalyzer ueber nextdns-manager/ (Settings-File, 0 Fehler-Ziel)
#   4. Dauer-Smokes nextdns-manager/tests/run-smokes.ps1 (End-to-End je Schicht,
#      je Smoke eigener pwsh-Prozess mit 30-s-Haerte-Timeout)
#
# Verfuegbarkeits-Vertrag: Fehlt Pester 5+/PSScriptAnalyzer, wird EINMAL
# automatisch installiert (CurrentUser); schlaegt das fehl (offline), wird
# die Schicht mit SKIP uebersprungen statt das Gate rot zu werfen - CI
# installiert die Module explizit (siehe .github/workflows/ci.yml).
#
# Exit-Codes: 0 = gruen (oder nur SKIPs), 1 = mindestens eine Schicht FAIL.

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Split-Path -Parent $PSScriptRoot
$isWindowsPlatform = [System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT
$failed = $false

function Test-ModuleMinimum {
	param([string]$Name, [version]$Minimum)
	$m = Get-Module -ListAvailable -Name $Name |
		Where-Object { $_.Version -ge $Minimum } |
		Sort-Object -Property Version -Descending |
		Select-Object -First 1
	return [bool]$m
}

function Ensure-TestModule {
	param([string]$Name, [version]$Minimum)
	if (Test-ModuleMinimum -Name $Name -Minimum $Minimum) {
		Import-Module $Name -MinimumVersion $Minimum -ErrorAction Stop
		return $true
	}
	# Einmalige Auto-Installation (CurrentUser); offline -> SKIP durch Aufrufer
	try {
		Write-Host ("Installiere fehlendes Modul {0} (>= {1}) ..." -f $Name, $Minimum) -ForegroundColor Yellow
		$installParams = @{ Name = $Name; Scope = 'CurrentUser'; Force = $true }
		if ($Name -eq 'Pester') { $installParams.SkipPublisherCheck = $true }
		Install-Module @installParams -ErrorAction Stop
		Import-Module $Name -MinimumVersion $Minimum -ErrorAction Stop
		return $true
	} catch {
		Write-Host ("SKIP {0}: Installation fehlgeschlagen ({1})" -f $Name, $_.Exception.Message) -ForegroundColor Yellow
		return $false
	}
}

# ------------------------------------------------- 1) Watchdog-DryRun (Windows)
$watchdog = Join-Path $repoRoot 'node-watchdog\node-watchdog.ps1'
if ($isWindowsPlatform -and (Test-Path $watchdog)) {
	$output = & pwsh -NoProfile -File $watchdog 2>&1
	if ($LASTEXITCODE -ne 0) {
		Write-Host "FAIL: Watchdog-DryRun brach mit Exit $LASTEXITCODE ab." -ForegroundColor Red
		$output | ForEach-Object { Write-Host $_ }
		$failed = $true
	} else {
		Write-Host 'OK   node-watchdog.ps1 DryRun laeuft (kein Kill ohne -Apply).'
	}
} else {
	Write-Host 'SKIP node-watchdog.ps1 DryRun (nur Windows bzw. Script nicht vorhanden).'
}

# ------------------------------------------------- 2) Pester-Suite
if (Ensure-TestModule -Name 'Pester' -Minimum ([version]'5.0.0')) {
	# Kind-Prozess per -File-Wrapper (run-pester.ps1): version-agnostisch
	# (Pester 5: RunResult, 6: $null bei Exit=$false -> deshalb Run.Exit=$true
	# + LASTEXITCODE) und ohne verschachteltes Quoting.
	$pesterWrapper = Join-Path $repoRoot 'nextdns-manager\tests\run-pester.ps1'
	& pwsh -NoProfile -File $pesterWrapper
	if ($LASTEXITCODE -ne 0) {
		Write-Host ("FAIL Pester (Exit {0})." -f $LASTEXITCODE) -ForegroundColor Red
		$failed = $true
	} else {
		Write-Host 'OK   Pester: alle Tests gruen (gemockt, keine Live-Calls).' -ForegroundColor Green
	}
} else {
	Write-Host 'SKIP Pester-Suite (Modul Pester >= 5 nicht verfuegbar).' -ForegroundColor Yellow
}

# ------------------------------------------------- 3) PSScriptAnalyzer
if (Ensure-TestModule -Name 'PSScriptAnalyzer' -Minimum ([version]'1.21.0')) {
	# Zwei Regelsaetze: Quelle (src/ + Root) und Tests/Smokes (Delegate-
	# Signaturen + Prompt-Helfer haben bewusst andere Muster, siehe
	# tests/PSScriptAnalyzerSettings.Tests.psd1).
	$moduleDir = Join-Path $repoRoot 'nextdns-manager'
	$settingsSrc = Join-Path $moduleDir 'PSScriptAnalyzerSettings.psd1'
	$settingsTests = Join-Path $moduleDir 'tests\PSScriptAnalyzerSettings.Tests.psd1'

	$srcDiagnostics = @(Invoke-ScriptAnalyzer -Path (Join-Path $moduleDir 'src') -Settings $settingsSrc -Recurse)
	$srcRoot = @()
	$srcRoot += @(Invoke-ScriptAnalyzer -Path (Join-Path $moduleDir 'NextDnsManager.psd1') -Settings $settingsSrc)
	$srcRoot += @(Invoke-ScriptAnalyzer -Path (Join-Path $moduleDir 'NextDnsManager.psm1') -Settings $settingsSrc)
	$srcRoot += @(Invoke-ScriptAnalyzer -Path (Join-Path $moduleDir 'run.ps1') -Settings $settingsSrc)
	$srcRoot += @(Invoke-ScriptAnalyzer -Path (Join-Path $moduleDir 'setup.ps1') -Settings $settingsSrc)
	$testDiagnostics = @(Invoke-ScriptAnalyzer -Path (Join-Path $moduleDir 'tests') -Settings $settingsTests -Recurse)

	$all = @()
	$all += $srcDiagnostics
	$all += $srcRoot
	$all += $testDiagnostics
	$issues = @($all | Where-Object { $_.Severity -in @('Error', 'Warning') })
	if ($issues.Count -gt 0) {
		Write-Host ("FAIL PSScriptAnalyzer: {0} Finding(s)." -f $issues.Count) -ForegroundColor Red
		$issues | ForEach-Object {
			Write-Host ("  {0}:{1} {2} {3}" -f (Split-Path -Leaf $_.ScriptPath), $_.Line, $_.Severity, $_.RuleName) -ForegroundColor Red
		}
		$failed = $true
	} else {
		Write-Host 'OK   PSScriptAnalyzer: 0 Findings (Quelle + Tests, 2 Regelsaetze).' -ForegroundColor Green
	}
} else {
	Write-Host 'SKIP PSScriptAnalyzer (Modul nicht verfuegbar).' -ForegroundColor Yellow
}

# ------------------------------------------------- 4) Dauer-Smokes
$smokeRunner = Join-Path $repoRoot 'nextdns-manager\tests\run-smokes.ps1'
if (Test-Path $smokeRunner) {
	& pwsh -NoProfile -File $smokeRunner
	if ($LASTEXITCODE -ne 0) {
		Write-Host "FAIL Dauer-Smokes (Exit $LASTEXITCODE)." -ForegroundColor Red
		$failed = $true
	} else {
		Write-Host 'OK   Dauer-Smokes: alle gruen.' -ForegroundColor Green
	}
} else {
	Write-Host 'SKIP Dauer-Smokes (Runner nicht vorhanden).'
}

Write-Host ''
if ($failed) {
	Write-Host 'Testlauf FEHLGESCHLAGEN.' -ForegroundColor Red
	exit 1
}
Write-Host 'Testlauf abgeschlossen - alle Schichten gruen.'
exit 0
