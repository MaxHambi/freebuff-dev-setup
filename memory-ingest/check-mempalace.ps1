#Requires -Version 5.1
# check-mempalace.ps1 - Diagnose: MemPalace-Anbindung in einem Lauf.
#
# Prueft drei Ebenen (Freebuff-Restart-Check):
#   1. Consent-State  - ~/.freebuff/mcp.json: mempalace-Eintrag vorhanden und
#                       enabled? Plus: Registrierungsdatei .mcp.json im Repo.
#   2. Binary-Smoke   - mempalace-mcp.exe via STDIO (initialize + tools/list),
#                       mit 30-s-Timeout ueber Background-Job.
#   3. Palast-Suche   - mempalace search mit Test-Query (CLI-Fallback-Pfad).
#
# Exit-Codes:
#   0 = alles gruen (Consent live, Binary OK, Suche OK)
#   2 = nur Consent fehlt - Binary + Suche gruen (CLI-Fallback ist der Weg)
#   1 = harter Fehler (Binary oder Suche defekt, Consent-Datei unlesbar)
#
# Benutzung:
#   pwsh -File memory-ingest/check-mempalace.ps1                 # Standard-Query
#   pwsh -File memory-ingest/check-mempalace.ps1 -Query "<begriff>"
#   pwsh -File memory-ingest/check-mempalace.ps1 -McpBin <pfad>  # Binary Override

param(
	[string]$Query = 'skill designer eval ranking',
	[string]$McpBin,
	[string]$RepoRoot,
	[string]$FreebuffMcpPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $RepoRoot) { $RepoRoot = Split-Path -Parent $scriptDir }
if (-not $FreebuffMcpPath) { $FreebuffMcpPath = Join-Path $env:USERPROFILE '.freebuff\mcp.json' }

function Get-PropSafe {
	param($Object, [string]$Name)
	if ($null -eq $Object) { return $null }
	$prop = $Object.PSObject.Properties[$Name]
	if ($prop) { return $prop.Value }
	return $null
}

Write-Host '===== MemPalace-Diagnose ====='
Write-Host ("Zeit: {0} | Repo: {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $RepoRoot)

# ------------------------------------------------- 1) Consent-State
$consentStatus = 'FAIL'
$consentDetail = ''
if (-not (Test-Path $FreebuffMcpPath)) {
	$consentDetail = "Datei fehlt: $FreebuffMcpPath"
} else {
	try {
		$state = Get-Content -Path $FreebuffMcpPath -Raw -Encoding UTF8 | ConvertFrom-Json
		$entry = $null
		$servers = Get-PropSafe $state 'servers'
		if ($servers) {
			foreach ($prop in $servers.PSObject.Properties) {
				if ((Get-PropSafe $prop.Value 'configKey') -eq 'mempalace') { $entry = $prop.Value; break }
			}
		}
		if (-not $entry) {
			$consentStatus = 'WARN'
			$consentDetail = 'kein mempalace-Eintrag - Consent-Prompt fuer .mcp.json in der Freebuff-UI bestaetigen'
		} elseif (-not (Get-PropSafe $entry 'enabled')) {
			$consentStatus = 'WARN'
			$consentDetail = 'mempalace-Eintrag vorhanden, aber disabled'
		} else {
			$tools = Get-PropSafe $entry 'allowedTools'
			$toolCount = if ($tools) { @($tools).Count } else { 0 }
			$consentStatus = 'OK'
			$consentDetail = "enabled, generation {0}, allowedTools: {1}" -f (Get-PropSafe $entry 'generation'), $toolCount
		}
	} catch {
		$consentDetail = "unlesbar: {0}" -f $_.Exception.Message
	}
}
$repoRegistration = Join-Path $RepoRoot '.mcp.json'
$registrationNote = if (Test-Path $repoRegistration) { 'Registrierungsdatei .mcp.json vorhanden' } else { 'Registrierungsdatei .mcp.json FEHLT im Repo' }
Write-Host ("[1/3] Consent : {0,-4} {1} | {2}" -f $consentStatus, $consentDetail, $registrationNote)

# ------------------------------------------------- 2) Binary-Smoke
$binStatus = 'FAIL'
$binDetail = ''
if (-not $McpBin) {
	$candidate = Join-Path $env:USERPROFILE '.local\bin\mempalace-mcp.exe'
	$cmd = Get-Command 'mempalace-mcp.exe' -ErrorAction SilentlyContinue
	if (Test-Path $candidate) { $McpBin = $candidate } elseif ($cmd) { $McpBin = $cmd.Source }
}
if (-not $McpBin -or -not (Test-Path $McpBin)) {
	$binDetail = 'mempalace-mcp.exe nicht gefunden (PATH oder ~/.local/bin)'
} else {
	$payload = Join-Path $env:TEMP 'check-mempalace-payload.jsonl'
	@(
		'{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"check-mempalace","version":"1.0.0"}}}',
		'{"jsonrpc":"2.0","method":"notifications/initialized"}',
		'{"jsonrpc":"2.0","id":2,"method":"tools/list"}'
	) | Set-Content -Path $payload -Encoding ASCII

	$job = Start-Job -ScriptBlock {
		param($exe, $p)
		Get-Content -Path $p | & $exe 2>$null
	} -ArgumentList $McpBin, $payload

	$out = $null
	if (Wait-Job $job -Timeout 30) { $out = @(Receive-Job $job) } else { Stop-Job $job -ErrorAction SilentlyContinue; $out = $null }
	Remove-Job $job -Force -ErrorAction SilentlyContinue

	if (-not $out) {
		$binDetail = 'keine Antwort innerhalb 30 s (Timeout oder Process-Exit ohne Output)'
	} else {
		$serverName = $null
		$serverVersion = $null
		$toolCount = -1
		foreach ($line in $out) {
			try { $msg = $line | ConvertFrom-Json } catch { continue }
			if ($msg.id -eq 1 -and $msg.result) {
				$info = Get-PropSafe $msg.result 'serverInfo'
				$serverName = Get-PropSafe $info 'name'
				$serverVersion = Get-PropSafe $info 'version'
			}
			if ($msg.id -eq 2 -and $msg.result) {
				$tools = Get-PropSafe $msg.result 'tools'
				if ($tools) { $toolCount = @($tools).Count }
			}
		}
		if ($serverName -and $toolCount -ge 0) {
			$binStatus = 'OK'
			$binDetail = "{0} {1}, {2} Tools via STDIO" -f $serverName, $serverVersion, $toolCount
		} else {
			$binDetail = "unvollstaendige Antwort (initialize={0}, tools/list={1})" -f [bool]$serverName, ($toolCount -ge 0)
		}
	}
}
Write-Host ("[2/3] Binary  : {0,-4} {1}" -f $binStatus, $binDetail)

# ------------------------------------------------- 3) Palast-Suche
$searchStatus = 'FAIL'
$searchDetail = ''
$cli = Get-Command 'mempalace' -ErrorAction SilentlyContinue
if (-not $cli) {
	$searchDetail = 'mempalace CLI nicht im PATH'
} else {
	$out = & mempalace search $Query 2>&1
	if ($LASTEXITCODE -ne 0) {
		$searchDetail = "search brach ab (Exit {0})" -f $LASTEXITCODE
	} else {
		$hits = ($out | Select-String -Pattern '^\s*\[\d+\]').Count
		$firstSource = ($out | Select-String -Pattern '^\s+Source:' | Select-Object -First 1)
		if ($hits -gt 0) {
			$searchStatus = 'OK'
			$searchDetail = "{0} Treffer fuer `"{1}`" ({2})" -f $hits, $Query, ($firstSource -replace '^\s*Source:\s*', '').Trim()
		} else {
			$searchStatus = 'WARN'
			$searchDetail = "0 Treffer fuer `"$Query`" - Palast antwortet, Query oder Korpus pruefen"
		}
	}
}
Write-Host ("[3/3] Suche   : {0,-4} {1}" -f $searchStatus, $searchDetail)

# ------------------------------------------------- Zusammenfassung
Write-Host '===== Zusammenfassung ====='
$overall = 'GRUEN'
if ($binStatus -eq 'FAIL' -or $searchStatus -eq 'FAIL') { $overall = 'ROT (harter Fehler)' }
elseif ($consentStatus -ne 'OK') { $overall = 'GELB (MCP-Consent fehlt, CLI-Fallback aktiv)' }
Write-Host ("Gesamt: {0}" -f $overall)

if ($binStatus -eq 'FAIL' -or $searchStatus -eq 'FAIL') { exit 1 }
if ($consentStatus -ne 'OK') { exit 2 }
exit 0
