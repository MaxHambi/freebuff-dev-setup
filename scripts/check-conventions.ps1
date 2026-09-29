# check-conventions.ps1 - Repo-Konventions-Waechter (Teil des Verify-Gates)
#
# Prueft harte Konventionen, deren Verletzung nie still geschehen darf:
#
# Check 1 - Claude-Bann (AGENTS.md-Namenskonvention):
#   Ordnerebene-Agent-Dateien heissen immer AGENTS.md, nie CLAUDE.md.
#   Getrackte Claude-Artefakte (CLAUDE.md, .claude/, old-Claude/) sind ein
#   Verstoess; der lokale Symlink CLAUDE.md -> AGENTS.md bleibt gitignored
#   und ist damit erlaubt.
#
# Check 2 - Mirror-Sync-Header (docs/issues/):
#   Jeder Issue-Mirror traegt einen mirror-sync-Header (sha256/synced).
#   Nicht-gepruefte Mirror-Nachtraege wuerden sonst still veralten.
#   (Delegiert an scripts/mirror-sync.ps1 -Check.)
#
# Beispiele:
#   pwsh -File scripts/check-conventions.ps1
[CmdletBinding()]
param(
	[switch]$SkipMirrorCheck
)

$ErrorActionPreference = 'Stop'
$fail = 0

# --- Check 1: Claude-Bann (getrackte Artefakte) ---
$tracked = @(& git ls-files)
$hits = @($tracked | Where-Object { $_ -match '(?i)(^|/)(claude\.md|\.claude|old-claude)(/|$)' })
if ($hits.Count -gt 0) {
	$hits | ForEach-Object { Write-Host "FAIL  Claude-Bann: getracktes Claude-Artefakt: $_" }
	$fail += $hits.Count
} else {
	Write-Host "OK    Claude-Bann: keine getrackten CLAUDE.md/.claude/old-Claude-Artefakte"
}

# --- Check 2: Mirror-Sync-Header ---
if (-not $SkipMirrorCheck) {
	$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
	& pwsh -NoProfile -File (Join-Path $scriptDir 'mirror-sync.ps1') -Check
	if ($LASTEXITCODE -ne 0) {
		Write-Host 'FAIL  Mirror-Sync: Mindestens ein Mirror ohne Header oder mit Drift'
		$fail++
	} else {
		Write-Host 'OK    Mirror-Sync: alle Mirrors mit gueltigem Header'
	}
}

if ($fail -gt 0) { Write-Host "check-conventions: $fail Verstoesse"; exit 1 }
Write-Host 'check-conventions: alle Konventions-Checks gruen'
exit 0
