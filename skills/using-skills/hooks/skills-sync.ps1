#Requires -Version 5.1
# Skills-Sync-Hook fuer den Skill "using-skills".
#
# ============================ STILLGELEGT (C1) ============================
# Issue #15 / Report-Durchgang 2026-09-30 (Operator-Beschluss):
# Dieser Hook ruft `routed scan` (CLI) und kann den Index dadurch EINKUERZEN:
# `removeMissingSkills(validPaths)` pruned alle Rows, die nicht unter den
# Environment-Pfaden des Detectors liegen — live bewiesen 2026-09-29
# (Prune 2512 Rows, 2867 -> 393). Die User-Bibliothek ~/.agents/skills ist
# im Detector bis routed v1.6.95 NICHT enthalten; jeder Scan-Versuch ist
# damit keine Registrierung, sondern ein Risiko. Registrierung nur noch
# bewusst und manuell via routed MCP `scan_skills` (upsert-only, kein
# Prune) — siehe ADR-002 und skills/using-skills/SKILL.md.
#
# RE-ENABLE (nur wenn ALLES erfuellt ist):
#   1. routed > v1.6.95 kennt ~/.agents/skills im Detector ODER es existiert
#      eine ueberpruefte ROUTED_CONFIG_PATH-Umgebung dafuer (dokumentiert in
#      ~/.agents/routed-environments.json).
#   2. `routed scan` pruned nicht mehr global (upsert-only oder
#      RemoveMissing auf die tatsaechlich gescannten Roots beschraenkt).
#   3. Operator-Freigabe im Issue #15/#17 dokumentiert.
#   Danach: diesen Block entfernen und Hook wieder normal nutzen.
# ===========================================================================
#
# Erkennt Aenderungen an den lokalen Skills-Ordnern und registriert sie im
# routed-Index (routed scan). Nur bei realen Aenderungen wird gescannt;
# der Zustand liegt als Snapshot in %APPDATA%\routed\skills-sync.state.json.
# Exit-Codes: 0 = alles im Index aktuell (kein Scan noetig),
#             1 = Aenderungen erkannt und registriert (Scan gelaufen),
#             2 = Fehler (routed fehlt oder Scan schlug fehl).
# Benutzung:  pwsh -File skills-sync.ps1 [-Force] [-HashContent]

param(
	[switch]$Force,
	[switch]$HashContent
)

# Stillgelegt (Issue #15, C1): bewusster, lauter Exit statt stiller Scan.
Write-Host 'SYNC-STILLGELEGT (Issue #15/C1): `routed scan` pruned den Index (live bewiesen 2026-09-29: 2512 Rows). Registrierung nur via routed MCP `scan_skills` (upsert-only). Re-Enable-Kriterien stehen im Dateikopf.'
exit 0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# 1) Ueberwachte Skills-Wurzeln (alle existierenden)
$roots = @(
	(Join-Path $env:USERPROFILE '.gemini\config\plugins'),
	(Join-Path $env:USERPROFILE '.agents\skills'),
	(Join-Path $env:USERPROFILE '.claude\skills')
) | Where-Object { Test-Path $_ }

# 2) Alle SKILL.md sammeln (begrenzte Tiefe, keine Backups/Node-Module)
$items = @{}
foreach ($root in $roots) {
	$files = Get-ChildItem -Path $root -Recurse -Filter 'SKILL.md' -Depth 6 -File -ErrorAction SilentlyContinue |
		Where-Object { $_.FullName -notmatch '\\node_modules\\|\.bak$|\\\.git\\' }
	foreach ($f in $files) {
		$fp = $f.FullName.Substring($root.Length).TrimStart('\')
		$stamp = '{0}:{1}' -f $f.LastWriteTimeUtc.Ticks, $f.Length
		if ($HashContent) {
			$sha = [System.Security.Cryptography.SHA256]::Create()
			try {
				$bytes = [System.IO.File]::ReadAllBytes($f.FullName)
				$stamp = ([BitConverter]::ToString($sha.ComputeHash($bytes)) -replace '-', '').Substring(0, 16)
			} finally { $sha.Dispose() }
		}
		$items[$fp] = $stamp
	}
}

# 3) Mit letztem Snapshot vergleichen
$statePath = Join-Path $env:APPDATA 'routed\skills-sync.state.json'
$previous = @{}
if (Test-Path $statePath) {
	try {
		$state = Get-Content -Raw $statePath | ConvertFrom-Json
		foreach ($p in $state.items.PSObject.Properties) { $previous[$p.Name] = $p.Value }
	} catch { Write-Warning 'Snapshot unlesbar - wird neu aufgebaut.' }
}

$added   = @($items.Keys | Where-Object { -not $previous.ContainsKey($_) })
$removed = @($previous.Keys | Where-Object { -not $items.ContainsKey($_) })
$changed = @($items.Keys | Where-Object { $previous.ContainsKey($_) -and $previous[$_] -ne $items[$_] })

if (-not $Force -and $added.Count -eq 0 -and $removed.Count -eq 0 -and $changed.Count -eq 0) {
	Write-Host ('SYNC: {0} Skills aktuell, keine Aenderungen.' -f $items.Count)
	exit 0
}

# 4) routed finden und Index aktualisieren
$routedPath = $null
$cmd = Get-Command 'routed.cmd' -ErrorAction SilentlyContinue
if ($cmd) {
	$routedPath = $cmd.Source
	if (-not $routedPath) { $routedPath = $cmd.Path }
}
if (-not $routedPath) {
	$candidate = Join-Path $env:LOCALAPPDATA 'Programs\Routed\bin\routed.cmd'
	if (Test-Path $candidate) { $routedPath = $candidate }
}
if (-not $routedPath) {
	Write-Warning 'routed nicht gefunden - Aenderungen konnten nicht registriert werden.'
	exit 2
}

Write-Host ('SYNC: {0} neu, {1} entfernt, {2} geaendert - routed scan laeuft...' -f $added.Count, $removed.Count, $changed.Count)
& $routedPath scan 2>$null
if ($LASTEXITCODE -ne 0) {
	Write-Warning 'routed scan fehlgeschlagen.'
	exit 2
}

# 5) Snapshot sichern (nur nach erfolgreichem Scan)
$null = New-Item -ItemType Directory -Force -Path (Split-Path -Parent $statePath)
$payload = [PSCustomObject]@{
	updatedAt = (Get-Date).ToUniversalTime().ToString('o')
	skillCount = $items.Count
	items = $items
} | ConvertTo-Json -Depth 4
[System.IO.File]::WriteAllText($statePath, $payload, [System.Text.UTF8Encoding]::new($false))

Write-Host ('SYNC: Index aktualisiert ({0} Skills registriert).' -f $items.Count)
exit 1