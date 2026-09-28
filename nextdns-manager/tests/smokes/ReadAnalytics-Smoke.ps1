# Dauermal-Smoke: Read/Analytics/Report (Slice #39).
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '..\..\NextDnsManager.psd1') -Force
$null = Initialize-NextDnsConfig -ApiKey 'testkey123' -ProfileId 'abc123'

# --- T1: reasons OHNE type (PLAN Befund 2) ---
$ep = Get-NextDnsAnalyticsEndpoint -Dimension 'reasons'
if ($ep -match 'type=') { throw "T1 FEHLGESCHLAGEN (type bei reasons): $ep" }
if ($ep -notmatch '^/profiles/abc123/analytics/reasons\?limit=10$') { throw "T1 Format: $ep" }
Write-Host 'T1 OK  reasons ohne type'

# --- T2: destinations type-Pflicht ---
$ep2 = Get-NextDnsAnalyticsEndpoint -Dimension 'destinations'
if ($ep2 -notmatch 'type=countries') { throw 'T2 FEHLGESCHLAGEN' }
try {
	$null = Get-NextDnsAnalyticsEndpoint -Dimension 'destinations' -Type 'ungueltig'
	throw 'T2b FEHLGESCHLAGEN (kein Throw bei ungueltigem type)'
} catch {
	if ("$_" -match 'FEHLGESCHLAGEN') { throw }
}
Write-Host 'T2 OK  destinations type-Pflicht (Default countries, ungueltig -> Throw)'

# --- T3: domains mit status/root ---
$ep3 = Get-NextDnsAnalyticsEndpoint -Dimension 'domains' -Status 'blocked' -Root
if ($ep3 -notmatch 'status=blocked' -or $ep3 -notmatch 'root=true') { throw 'T3 FEHLGESCHLAGEN' }
Write-Host 'T3 OK  domains mit status/root'

# --- T4: ;series-Suffix ---
$ep4 = Get-NextDnsAnalyticsEndpoint -Dimension 'status' -Series
if ($ep4 -notmatch 'analytics/status;series\?') { throw 'T4 FEHLGESCHLAGEN' }
Write-Host 'T4 OK  ;series-Suffix'

# --- T5: Limit-Clamps Analytics (1..500) / Logs (10..1000) ---
$a = Get-NextDnsAnalyticsEndpoint -Dimension 'status' -Limit 9999
if ($a -notmatch 'limit=500') { throw 'T5 FEHLGESCHLAGEN (analytics clamp)' }
Set-NextDnsHttpDelegate -Delegate {
	param($Uri, $Method, $Headers, $JsonBody, $TimeoutSec)
	$script:logUris += $Uri
	[PSCustomObject]@{ StatusCode = 200; Content = '{"data":[]}'; Headers = $null; TransportError = $null }
}
$script:logUris = @()
$null = Get-NextDnsLogs -Limit 9999
$null = Get-NextDnsLogs -Limit 5
if ($script:logUris[0] -notmatch 'limit=1000') { throw 'T5b FEHLGESCHLAGEN (logs upper)' }
if ($script:logUris[1] -notmatch 'limit=10') { throw 'T5c FEHLGESCHLAGEN (logs lower)' }
Write-Host 'T5 OK  Clamps Analytics 500 / Logs 1000+10'

# --- T6: Logs-Filter im Endpoint ---
Set-NextDnsHttpDelegate -Delegate {
	param($Uri, $Method, $Headers, $JsonBody, $TimeoutSec)
	$script:capturedUri = $Uri
	[PSCustomObject]@{ StatusCode = 200; Content = '{"data":[{"timestamp":"t","domain":"d","status":"blocked"}]}'; Headers = $null; TransportError = $null }
}
$null = Get-NextDnsLogs -Status blocked -Search 'facebook' -Device 'DEV1' -From '-24h' -Sort asc -Raw
$u = $script:capturedUri
foreach ($must in @('status=blocked', 'search=facebook', 'device=DEV1', 'from=-24h', 'sort=asc', 'raw=1')) {
	if ($u -notmatch [regex]::Escape($must)) { throw "T6 FEHLGESCHLAGEN (fehlt: $must)" }
}
Write-Host 'T6 OK  Logs-Filter-Satz in Query'

# --- T7: Read-Funktionen ueber Delegate ---
Set-NextDnsHttpDelegate -Delegate {
	param($Uri, $Method, $Headers, $JsonBody, $TimeoutSec)
	if ($Uri -match '/profiles$') {
		[PSCustomObject]@{ StatusCode = 200; Content = '{"data":[{"id":"abc123","name":"Home"}]}'; Headers = $null; TransportError = $null }
	} else {
		[PSCustomObject]@{ StatusCode = 200; Content = '{"data":{"name":"Home","id":"abc123"}}'; Headers = $null; TransportError = $null }
	}
}
$p = Get-NextDnsProfiles
$pf = Get-NextDnsProfile
if (-not $p.Ok -or -not $pf.Ok -or $pf.Data.name -ne 'Home') { throw 'T7 FEHLGESCHLAGEN' }
Write-Host 'T7 OK  Read-Funktionen (Liste + Einzelprofil)'

# --- T8: Full-Report ohne Logs ---
# Plattform-neutral: $env:TEMP ist Windows-idiomatisch (auf Linux leer ->
# StrictMode-Null-Bind); [IO.Path]::GetTempPath() funktioniert auf beiden.
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("ndm-report-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $tmp | Out-Null
$rep = Export-NextDnsFullReport -Directory $tmp -WithoutLogs
$content = Get-Content -Path $rep.Path -Raw
foreach ($must in @('NEXTDNS FULL REPORT', 'PROFIL-DETAILS', 'EINSTELLUNGEN', 'DENYLIST', 'ALLOWLIST', 'ANALYTICS', 'uebersprungen', 'FEHLER-ZUSAMMENFASSUNG')) {
	if ($content -notmatch [regex]::Escape($must)) { throw "T8 FEHLGESCHLAGEN (absent: $must)" }
}
Remove-Item -Recurse -Force $tmp
Write-Host 'T8 OK  Full-Report ohne-Logs-Modus mit allen Sektionen'

Set-NextDnsHttpDelegate -Delegate $null
Write-Host '=== Read/Analytics-Smoke: 8/8 gruen ===' -ForegroundColor Green
exit 0
