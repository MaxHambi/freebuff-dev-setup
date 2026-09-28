# Dauermal-Smoke: Core (Slice #38) - laeuft in run-smokes.ps1 als zusaetzliche
# Pruefschicht NEBEN der Pester-Suite (Operator-Anforderung: Smokes bleiben
# als Gesamtsitzungs-Pruefung erhalten).
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '..\..\NextDnsManager.psd1') -Force
$null = Initialize-NextDnsConfig -ApiKey 'testkey123' -ProfileId 'abc123'

# --- T1: 200 OK + errors[] = FEHLER (PLAN Befund 1) ---
Set-NextDnsHttpDelegate -Delegate {
	param($Uri, $Method, $Headers, $JsonBody, $TimeoutSec)
	[PSCustomObject]@{ StatusCode = 200; Content = '{"errors":[{"code":"invalid","detail":"badwebsite is not a valid domain"}]}'; Headers = $null; TransportError = $null }
}
$r = Invoke-NextDnsApi -Method 'POST' -Endpoint '/profiles/abc123/denylist' -Body @{ id = 'badwebsite'; active = $true }
if ($r.Ok) { throw 'T1 FEHLGESCHLAGEN (errors[] als Erfolg gewertet)' }
Write-Host 'T1 OK  200+errors[] -> Fehler'

# --- T2: 200 + data = OK, Envelope aufgeloest ---
Set-NextDnsHttpDelegate -Delegate {
	param($Uri, $Method, $Headers, $JsonBody, $TimeoutSec)
	[PSCustomObject]@{ StatusCode = 200; Content = '{"data":[{"id":"x"}],"meta":{"pagination":{"cursor":null}}}'; Headers = $null; TransportError = $null }
}
$r2 = Invoke-NextDnsApi -Method 'GET' -Endpoint '/profiles/abc123/denylist'
if (-not $r2.Ok -or @($r2.Data).Count -ne 1) { throw 'T2 FEHLGESCHLAGEN' }
Write-Host 'T2 OK  200+data -> OK, Envelope aufgeloest'

# --- T3: Clamps (Befund 4) ---
$c1 = Get-NextDnsClampedLimit -Limit 5 -Min 10 -Max 1000
$c2 = Get-NextDnsClampedLimit -Limit 5000 -Min 10 -Max 1000
$c3 = Get-NextDnsClampedLimit -Limit 50 -Min 10 -Max 1000
if ($c1 -ne 10 -or $c2 -ne 1000 -or $c3 -ne 50) { throw 'T3 FEHLGESCHLAGEN' }
Write-Host 'T3 OK  Clamps 5->10, 5000->1000, 50->50'

# --- T4: Pagination-Dedupe (Cursor-Wiederholung) ---
Set-NextDnsHttpDelegate -Delegate {
	param($Uri, $Method, $Headers, $JsonBody, $TimeoutSec)
	if ($Uri -match 'cursor=') {
		[PSCustomObject]@{ StatusCode = 200; Content = '{"data":[{"id":"a"},{"id":"c"}],"meta":{"pagination":{"cursor":null}}}'; Headers = $null; TransportError = $null }
	} else {
		[PSCustomObject]@{ StatusCode = 200; Content = '{"data":[{"id":"a"},{"id":"b"}],"meta":{"pagination":{"cursor":"cur1"}}}'; Headers = $null; TransportError = $null }
	}
}
$r4 = Get-NextDnsAllPages -Endpoint '/profiles/abc123/logs' -PageLimit 2 -SleepMs 0
if ($r4.Entries.Count -ne 3) { throw "T4 FEHLGESCHLAGEN (Entries=$($r4.Entries.Count), erwartet 3)" }
Write-Host 'T4 OK  Pagination-Dedupe (a,b,c aus 2 Seiten mit Wiederholung)'

# --- T5: 429 -> Retry -> OK (Befund 3) ---
Set-NextDnsHttpDelegate -Delegate {
	param($Uri, $Method, $Headers, $JsonBody, $TimeoutSec)
	$script:t5calls = ($script:t5calls + 1)
	if ($script:t5calls -eq 1) {
		[PSCustomObject]@{ StatusCode = 0; Content = ''; Headers = $null; TransportError = 'HTTP 429 - rate limited' }
	} else {
		[PSCustomObject]@{ StatusCode = 200; Content = '{"data":[{"id":"ok"}]}'; Headers = $null; TransportError = $null }
	}
}
$script:t5calls = 0
$r5 = Invoke-NextDnsApi -Method 'GET' -Endpoint '/profiles/abc123/status' -MaxRetries 2
if ($script:t5calls -ne 2 -or -not $r5.Ok) { throw 'T5 FEHLGESCHLAGEN (kein Retry bei 429)' }
Write-Host 'T5 OK  429 -> Retry -> OK'

# --- T6: Kein Secret in Fehlern ---
Set-NextDnsHttpDelegate -Delegate {
	param($Uri, $Method, $Headers, $JsonBody, $TimeoutSec)
	[PSCustomObject]@{ StatusCode = 0; Content = ''; Headers = $null; TransportError = 'boom' }
}
$r6 = Invoke-NextDnsApi -Method 'GET' -Endpoint '/profiles/abc123' -MaxRetries 0
if ($r6.Error -match 'testkey123') { throw 'T6 FEHLGESCHLAGEN (Secret geleakt)' }
Write-Host 'T6 OK  Kein Secret-Leak in Fehlermeldungen'

Set-NextDnsHttpDelegate -Delegate $null
Write-Host '=== Core-Smoke: 6/6 gruen ===' -ForegroundColor Green
exit 0
