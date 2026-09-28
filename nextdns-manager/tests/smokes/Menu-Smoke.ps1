# Dauermal-Smoke: Menu/CLI (Slice #41).
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '..\..\NextDnsManager.psd1') -Force

# --- T1: Font-Erkennung trifft eine der Operator-Gruppen ---
Initialize-NextDnsIcons
$info = Get-NextDnsFontInfo
if ($info.Mode -ne 'nerd') { throw "T1 FEHLGESCHLAGEN (Mode=$($info.Mode))" }
if ($info.Font -notmatch 'JetBrains|Meslo|Terminess') { throw "T1b FEHLGESCHLAGEN (Font ausserhalb der Gruppen: $($info.Font))" }
Write-Host "T1 OK  Nerd-Font erkannt: $($info.Font)"

# --- T2: ASCII-Fallback erzwingbar ---
Set-NextDnsIconMode -Mode 'ascii'
$icons2 = Get-NextDnsIcons
if ($icons2.Mode -ne 'ascii' -or $icons2.Check -ne 'OK') { throw 'T2 FEHLGESCHLAGEN' }
Initialize-NextDnsIcons
Write-Host 'T2 OK  ASCII-Fallback'

# --- T3: Dispatch-Tabelle vollstaendig ---
$table = Get-NextDnsMenuTable
if ($table.Count -ne 17) { throw "T3 FEHLGESCHLAGEN (count=$($table.Count))" }
$missing = foreach ($e in $table) { if (-not (Get-Command $e.Function -ErrorAction SilentlyContinue)) { $e.Function } }
if ($missing) { throw "T3b FEHLGESCHLAGEN (fehlend: $($missing -join ', '))" }
$keys = @($table | ForEach-Object { $_.Key })
if ($keys.Count -ne ($keys | Sort-Object -Unique).Count) { throw 'T3c FEHLGESCHLAGEN (doppelte Keys)' }
Write-Host 'T3 OK  17 Actions, Keys eindeutig, Funktionen vorhanden'

# --- T4: Write-Actions markiert ---
$writes = @($table | Where-Object { $_.Kind -eq 'write' })
if ($writes.Count -lt 5) { throw 'T4 FEHLGESCHLAGEN' }
Write-Host "T4 OK  $($writes.Count) Write-Actions markiert"

# --- T5/T6: Action-Ausfuehrung ueber Delegate ---
$null = Initialize-NextDnsConfig -ApiKey 'testkey123' -ProfileId 'abc123'
Set-NextDnsHttpDelegate -Delegate {
	param($Uri, $Method, $Headers, $JsonBody, $TimeoutSec)
	if ($Uri -match '/profiles$') {
		[PSCustomObject]@{ StatusCode = 200; Content = '{"data":[{"id":"abc123","name":"Home"}]}'; Headers = $null; TransportError = $null }
	} else {
		[PSCustomObject]@{ StatusCode = 200; Content = '{"data":{"id":"abc123","name":"Home"}}'; Headers = $null; TransportError = $null }
	}
}
$entry = $table | Where-Object { $_.Key -eq '1' }
$out = Invoke-NextDnsMenuAction -Entry $entry 6>&1 | Out-String
if ($out -notmatch 'Home') { throw 'T5 FEHLGESCHLAGEN' }
Write-Host 'T5 OK  Action-Ausfuehrung (Read-Pfad)'

Set-NextDnsHttpDelegate -Delegate {
	param($Uri, $Method, $Headers, $JsonBody, $TimeoutSec)
	[PSCustomObject]@{ StatusCode = 200; Content = '{"errors":[{"code":"invalid","detail":"kaputt"}]}'; Headers = $null; TransportError = $null }
}
$out2 = Invoke-NextDnsMenuAction -Entry $entry 6>&1 | Out-String
if ($out2 -notmatch 'kaputt') { throw 'T6 FEHLGESCHLAGEN' }
Write-Host 'T6 OK  Fehlerpfad sichtbar'

Set-NextDnsHttpDelegate -Delegate $null
Write-Host '=== Menu-Smoke: 6/6 gruen ===' -ForegroundColor Green
exit 0
