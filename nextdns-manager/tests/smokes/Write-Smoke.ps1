# Dauermal-Smoke: Write-Safety (Slice #40).
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '..\..\NextDnsManager.psd1') -Force
$null = Initialize-NextDnsConfig -ApiKey 'testkey123' -ProfileId 'abc123'

$script:calls = @()
Set-NextDnsHttpDelegate -Delegate {
	param($Uri, $Method, $Headers, $JsonBody, $TimeoutSec)
	$script:calls += "$Method $Uri"
	if ($Uri -match 'denylist' -and $Method -eq 'POST' -and $JsonBody -match 'badwebsite') {
		return [PSCustomObject]@{ StatusCode = 200; Content = '{"errors":[{"code":"invalid","detail":"badwebsite is not a valid domain"}]}'; Headers = $null; TransportError = $null }
	}
	if ($Method -eq 'DELETE') {
		return [PSCustomObject]@{ StatusCode = 200; Content = ''; Headers = $null; TransportError = $null }
	}
	return [PSCustomObject]@{ StatusCode = 200; Content = '{"data":{"id":"ok"}}'; Headers = $null; TransportError = $null }
}

# --- T1: -WhatIf -> KEIN HTTP-Call ---
$before = $script:calls.Count
$res = Add-NextDnsDenylistEntry -Domains 'whatif.example.com' -WhatIf
if ($script:calls.Count -ne $before) { throw 'T1 FEHLGESCHLAGEN (HTTP-Call trotz WhatIf)' }
if ($res.Ok) { throw 'T1b FEHLGESCHLAGEN (WhatIf-Ergebnis ist ok)' }
Write-Host 'T1 OK  -WhatIf erzeugt keinen HTTP-Call'

# --- T2: gueltige Domain -> Ok ---
$r2 = Add-NextDnsDenylistEntry -Domains 'good.example.com'
if (-not $r2.Ok) { throw 'T2 FEHLGESCHLAGEN' }
Write-Host 'T2 OK  Add gueltige Domain'

# --- T3: ungueltige Domain (200+errors[]) -> Fehler mit Detail (Befund 1/6) ---
$r3 = Add-NextDnsDenylistEntry -Domains 'badwebsite'
if ($r3.Ok) { throw 'T3 FEHLGESCHLAGEN (errors[] als Erfolg)' }
if ($r3.Error -notmatch 'not a valid domain') { throw 'T3b FEHLGESCHLAGEN (Detail fehlt)' }
Write-Host 'T3 OK  errors[] je Domain ausgewertet'

# --- T4: Remove nutzt DELETE am Child-Endpoint ---
$r4 = Remove-NextDnsDenylistEntry -Domains 'good.example.com'
$lastCall = $script:calls[$script:calls.Count - 1]
if (-not $r4.Ok) { throw 'T4 FEHLGESCHLAGEN' }
if ($lastCall -notmatch 'DELETE .*/denylist/good\.example\.com$') { throw 'T4b FEHLGESCHLAGEN (Endpoint)' }
Write-Host 'T4 OK  DELETE am Child-Endpoint'

# --- T5: Batch mit Mischresultat ---
$r5 = @(Add-NextDnsDenylistEntry -Domains @('good.example.com', 'badwebsite', ''))
if ($r5.Count -ne 3) { throw 'T5 FEHLGESCHLAGEN (count)' }
if (@($r5 | Where-Object { $_.Ok }).Count -ne 1) { throw 'T5b FEHLGESCHLAGEN (oks)' }
Write-Host 'T5 OK  Batch-Mischresultat (1 OK, 2 Fehler)'

# --- T6: Set-NextDnsSettings PATCH + ValidateSet ---
$r6 = Set-NextDnsSettings -Section 'settings/blockPage' -Body @{ enabled = $true }
$lastCall = $script:calls[$script:calls.Count - 1]
if (-not $r6.Ok) { throw 'T6 FEHLGESCHLAGEN' }
if ($lastCall -notmatch 'PATCH .*/settings/blockPage$') { throw 'T6b FEHLGESCHLAGEN (Endpoint)' }
try {
	$null = Set-NextDnsSettings -Section 'hacker/path' -Body @{} -WhatIf
	throw 'T6c FEHLGESCHLAGEN (ValidateSet hat nicht gegriffen)'
} catch {
	if ("$_" -match 'FEHLGESCHLAGEN') { throw }
}
Write-Host 'T6 OK  Settings-PATCH + ValidateSet'

# --- T7: Clear-NextDnsLogs ConfirmImpact=High ---
$cmd = Get-Command Clear-NextDnsLogs
$attr = $cmd.ScriptBlock.Attributes | Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] } | Select-Object -First 1
if ($attr.ConfirmImpact -ne 'High') { throw 'T7 FEHLGESCHLAGEN (ConfirmImpact)' }
if (-not $attr.SupportsShouldProcess) { throw 'T7b FEHLGESCHLAGEN (SupportsShouldProcess)' }
$r7b = Clear-NextDnsLogs -Confirm:$false
$lastCall = $script:calls[$script:calls.Count - 1]
if (-not $r7b.Ok) { throw 'T7c FEHLGESCHLAGEN' }
if ($lastCall -notmatch 'DELETE .*/logs$') { throw 'T7d FEHLGESCHLAGEN (Endpoint)' }
Write-Host 'T7 OK  ConfirmImpact=High + erzwungene Ausfuehrung'

# --- T8: Allowlist-Spiegel ---
$r8 = @(Add-NextDnsAllowlistEntry -Domains @('allow.example.com'))[0]
$r8b = @(Remove-NextDnsAllowlistEntry -Domains @('allow.example.com'))[0]
if (-not $r8.Ok -or -not $r8b.Ok) { throw 'T8 FEHLGESCHLAGEN' }
Write-Host 'T8 OK  Allowlist add/remove'

Set-NextDnsHttpDelegate -Delegate $null
Write-Host '=== Write-Smoke: 8/8 gruen ===' -ForegroundColor Green
exit 0
