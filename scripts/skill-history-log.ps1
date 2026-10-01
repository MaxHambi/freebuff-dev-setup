#Requires -Version 5.1
# skill-history-log.ps1 - Haengt einen Skill-Ausfuehrungs-Eintrag an
# skill-history.md (Changelog der Skill-Nutzung) und macht optional direkt
# einen eigenen Commit mit dem Label chore(skill-history).
#
# Aufrufe:
#   Manuell:
#     pwsh -File scripts/skill-history-log.ps1 -SkillName "<name>" `
#          -Detail "<kontext/ausloeser>" -Ergebnis "<fazit>"
#   Als Session-Hook (PostToolUse auf Tool "Skill", JSON am stdin):
#     pwsh -File scripts/skill-history-log.ps1 -FromHookJson
#
# Switches:
#   -NoCommit          nur Eintrag schreiben, kein Commit
#   -HistoryFile <pfad> Override fuer die Zieldatei (Tests)
#
# Exit-Codes: 0 = ok, 1 = Fehler (Eintrag nicht geschrieben/Commit fehlgeschlagen).
# Als Hook eingebunden: Fehler blockieren die Session nie (Hook-Wrapper
# faengt Exit 1 ab und meldet nur, siehe .claude/settings.json).

param(
	[string]$SkillName,
	[string]$Detail,
	[string]$Ergebnis,
	[string]$Quelle = 'manuell',
	[switch]$FromHookJson,
	[switch]$NoCommit,
	[string]$HistoryFile
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Fail {
	param([string]$Message)
	Write-Error $Message
	exit 1
}

# ---------------------------------------------------------------- Ziel-Datei
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $HistoryFile) { $HistoryFile = Join-Path (Split-Path -Parent $scriptDir) 'skill-history.md' }
if (-not (Test-Path $HistoryFile)) {
	Fail "skill-history.md nicht gefunden: $HistoryFile"
}
# Repo-Root aus der History-Datei ableiten (Datei liegt im Repo-Root); liegt
# die Datei ausserhalb eines Git-Repos, wird nur der Eintrag geschrieben.
$historyDir = Split-Path -Parent $HistoryFile
$repoRoot = $null
try {
	git -C $historyDir rev-parse --is-inside-work-tree *> $null
	if ($LASTEXITCODE -eq 0) { $repoRoot = (git -C $historyDir rev-parse --show-toplevel 2>$null) }
} catch { $repoRoot = $null }
$inGitRepo = [bool]$repoRoot

# ---------------------------------------------------------------- Eingaben
if ($FromHookJson) {
	# Claude-Code-Hooks liefern ein JSON am stdin; relevant sind
	# tool_name = "Skill" und tool_input mit Skill-Name/Argumenten.
	$stdin = [Console]::In.ReadToEnd()
	if (-not $stdin) { Fail 'Kein Hook-JSON am stdin empfangen.' }
	try {
		$hook = $stdin | ConvertFrom-Json
	} catch {
		Fail "Hook-JSON nicht parsbar: $($_.Exception.Message)"
	}
	$toolName = [string]$hook.tool_name
	if ($toolName -and $toolName -ne 'Skill') {
		# Nicht unser Event - still beenden (Exit 0, kein Eintrag).
		exit 0
	}
	$input0 = $hook.tool_input
	if ($input0) {
		if (-not $SkillName) {
			if ($input0.skill) { $SkillName = [string]$input0.skill }
			elseif ($input0.name) { $SkillName = [string]$input0.name }
			elseif ($input0.command) { $SkillName = [string]$input0.command }
		}
		if (-not $Detail) {
			$argsRaw = ''
			if ($input0.args) { $argsRaw = [string]$input0.args }
			elseif ($input0.arguments) { $argsRaw = [string]$input0.arguments }
			elseif ($input0.input) { $argsRaw = [string]$input0.input }
			if ($argsRaw) {
				if ($argsRaw.Length -gt 180) { $argsRaw = $argsRaw.Substring(0, 180) + '...' }
				$Detail = "Aufruf mit Argumenten: $argsRaw"
			}
		}
	}
	if (-not $SkillName) { Fail 'Hook-JSON enthaelt keinen Skill-Namen.' }
	if (-not $Detail) { $Detail = 'Skill-Ausfuehrung via Session-Hook (kein Kontext uebergeben).' }
	if ($Quelle -eq 'manuell') { $Quelle = 'session-hook' }
}

if (-not $SkillName) { Fail 'Parameter -SkillName fehlt.' }
$SkillName = $SkillName.Trim()
if (-not $SkillName) { Fail 'Parameter -SkillName ist leer.' }
if (-not $Detail) { $Detail = 'kein Kontext angegeben' }
if (-not $Ergebnis) { $Ergebnis = 'offen (wird nach der Ausfuehrung ergaenzt)' }

# ---------------------------------------------------------------- Eintrag bauen
$gitHead = ''
$branch = '?'
if ($inGitRepo) {
	try {
		$gitHead = (git -C $repoRoot rev-parse --short HEAD 2>$null)
		$branch = (git -C $repoRoot rev-parse --abbrev-ref HEAD 2>$null)
	} catch { $gitHead = ''; $branch = '?' }
}
if (-not $gitHead) { $gitHead = 'unbekannt' }
if (-not $branch) { $branch = '?' }

$hostName = [System.Net.Dns]::GetHostName()
$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm'
$sanitized = ($SkillName -replace '[\r\n]+', ' ').Trim()
$detailClean = ($Detail -replace '\r?\n', ' ').Trim()
$ergebnisClean = ($Ergebnis -replace '\r?\n', ' ').Trim()

$entry = @()

## <skill-name> - <JJJJ-MM-TT HH:MM>
$entry += "## $sanitized - $timestamp"
$entry += "- **Kontext/Ausloeser:** $detailClean"
$entry += "- **Umgebung:** Branch ``$branch`` @ ``$gitHead``, Host: $hostName"
$entry += "- **Quelle:** $Quelle"
$entry += "- **Ergebnis:** $ergebnisClean"
$entry += ''
$entryText = ($entry -join "`r`n") + "`r`n"

# ---------------------------------------------------------------- Einfuegen
# Neuester Eintrag oben: direkt nach dem Marker einsetzen.
$content = Get-Content -Path $HistoryFile -Raw
$marker = '<!-- skill-history:entries-start -->'
$markerIdx = $content.IndexOf($marker)
if ($markerIdx -eq -1) {
	Fail "Marker '$marker' in $HistoryFile nicht gefunden."
}
$insertAt = $markerIdx + $marker.Length
$lineBreakIdx = $content.IndexOf("`n", $insertAt)
if ($lineBreakIdx -ne -1) { $insertAt = $lineBreakIdx + 1 }

$newContent = $content.Substring(0, $insertAt) + "`r`n" + $entryText + $content.Substring($insertAt)

# ---------------------------------------------------------------- Schreiben
# BOM-frei schreiben (UTF8 ohne BOM, kompatibel zu PS 5.1 und 7).
[System.IO.File]::WriteAllText($HistoryFile, $newContent, [System.Text.UTF8Encoding]::new($false))
Write-Host ("skill-history: Eintrag fuer '{0}' geschrieben ({1})." -f $sanitized, $HistoryFile)

if ($NoCommit -or -not $inGitRepo) {
	if (-not $inGitRepo) { Write-Host 'skill-history: Datei liegt ausserhalb eines Git-Repos - kein Commit.' }
	else { Write-Host 'skill-history: kein Commit (-NoCommit).' }
	exit 0
}

# ---------------------------------------------------------------- Commit
$stage = git -C $repoRoot add -- $HistoryFile 2>&1
if ($LASTEXITCODE -ne 0) { Fail "git add fehlgeschlagen: $stage" }

$diff = git -C $repoRoot diff --cached --quiet -- $HistoryFile
if ($LASTEXITCODE -eq 0) {
	Write-Host 'skill-history: keine inhaltliche Aenderung - nichts zu committen.'
	exit 0
}

$subjectPart = $sanitized
if ($subjectPart.Length -gt 60) { $subjectPart = $subjectPart.Substring(0, 60) + '...' }
$commitSubject = "chore(skill-history): $subjectPart"
if ($commitSubject.Length -gt 100) { $commitSubject = $commitSubject.Substring(0, 100) }

$commitArgs = @(
	'-C', $repoRoot,
	'commit',
	'-m', $commitSubject,
	'-m', 'Skill-Ausfuehrung protokolliert (siehe skill-history.md).',
	'-m', 'AI-Assisted: Codebuff (Buffy)',
	'--', $HistoryFile
)
$out = git @commitArgs 2>&1
if ($LASTEXITCODE -ne 0) {
	Fail "git commit fehlgeschlagen: $out"
}
$hash = git -C $repoRoot rev-parse --short HEAD
Write-Host ("skill-history: Commit {0} - {1}" -f $hash, $commitSubject)
