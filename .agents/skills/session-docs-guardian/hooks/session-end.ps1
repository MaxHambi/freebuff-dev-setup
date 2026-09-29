#Requires -Version 5.1
# Session-Docs-Guardian Hook: wird bei Session-Ende ausgefuehrt und meldet,
# welche Doku-Artefakte seit dem letzten Dokumentations-Commit veraendet sind.
# Output: Report auf stdout; Exit 0 immer (Hook darf niemals blockieren).
# Optionaler Parameter -Check verlangt Fundstelle als Exit 1 (fuer strenge Umgebungen).

param(
    [switch]$Check
)

$ErrorActionPreference = 'SilentlyContinue'

$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) {
    Write-Output 'session-docs-guardian: kein Git-Repo - uebersprungen.'
    exit 0
}

# Letzter Commit, der ausschliesslich Doku-Pfade anfasste (Basis des Vergleichs)
$docPaths = @('README.md', 'CHANGELOG.md', 'docs/', 'skills-manager/docs/')
$lastDocCommit = $null
foreach ($commit in (git log --pretty='%H|%ci|%s' -30)) {
    $parts = $commit -split '\|', 3
    if ($parts.Count -lt 3) { continue }
    $hash = $parts[0]
    $changed = git show --name-only --pretty=format: $hash 2>$null | Where-Object { $_ -ne '' }
    $isDocsOnly = ($changed | Where-Object {
        $p = $_
        ($docPaths | Where-Object { $p.StartsWith($_) }).Count -gt 0
    }).Count -eq @($changed).Count -and @($changed).Count -gt 0
    if ($isDocsOnly) {
        $lastDocCommit = $hash
        break
    }
}

$stale = New-Object System.Collections.Generic.List[string]

if ($lastDocCommit) {
    # Alles seit dem letzten Doku-Commit als veraendet melden
    $dirty = git log "$lastDocCommit..HEAD" --name-only --pretty=format: 2>$null |
        Where-Object { $_ -ne '' } | Sort-Object -Unique
    foreach ($file in $dirty) {
        $stale.Add($file) | Out-Null
    }
} else {
    # Kein Doku-Commit in den letzten 30 Commits - alles seit 30 Commits pruefen
    $dirty = git log -30 --name-only --pretty=format: 2>$null |
        Where-Object { $_ -ne '' } | Sort-Object -Unique
    foreach ($file in $dirty) {
        $stale.Add($file) | Out-Null
    }
}

# Uncommitted Aenderungen ebenfalls melden
$uncommitted = git status --porcelain 2>$null | ForEach-Object { $_.Substring(3).Trim() }
foreach ($file in $uncommitted) {
    if ($stale -notcontains $file) { $stale.Add($file) | Out-Null }
}

# Klassifizierung: welche Doku-Artefakte sollten angelupft werden?
$targets = [ordered]@{
    'AGENTS.md'                        = 'AGENTS.md: Struktur/Commands/CI/Konventionen aktualisieren'
    'README.md'                        = 'README: Komponenten-Tabelle / Abschnitte pruefen'
    'CHANGELOG.md'                     = 'CHANGELOG: [Unreleased]-Eintraege ergaenzen'
    'docs/decisions/'                  = 'ADRs: neue Entscheidungen aus dieser Session dokumentieren'
    'docs/sessions.md'                 = 'Session-Summary ergaenzen (docs/sessions.md)'
    'skills-manager/docs/'             = 'Skills-Manager-Doku (PRD/PROCESS/ARCHITECTURE/API/USER_GUIDE)'
    'docs/index.md'                    = 'Doku-Landkarte aktualisieren'
}

$report = New-Object System.Collections.Generic.List[string]
$report.Add('=== session-docs-guardian ===')

$relevantCount = 0
foreach ($key in $targets.Keys) {
    $touches = $stale | Where-Object { $_ -like "$key*" -or $_ -eq $key }
    if ($touches.Count -gt 0) {
        $relevantCount++
        $report.Add("STALE  $key -> $($targets[$key]) ($($touches.Count) geaenderte Datei(en))")
    }
}

# Neue Skills erkennen (unversionierte SKILL.md oder neue Ordnernamen unter skills/)
$newSkills = git status --porcelain 2>$null | Where-Object { $_ -match '^\?\? skills/[^/]+/' }
if ($newSkills) {
    $relevantCount++
    $report.Add("STALE  README Skills-Tabelle -> neue repo-eigene Skills registrieren:")
    foreach ($s in $newSkills) { $report.Add("       $s") }
}

if ($relevantCount -eq 0) {
    $report.Add('OK      Doku ist aktuell - keine Aktion noetig.')
    $report | ForEach-Object { Write-Output $_ }
    exit 0
}

$report.Add('')
$report.Add('Aktionsaufruf: session-docs-guardian Skill ausfuehren (Doku-Update + Session-Summary + Commit).')
$report | ForEach-Object { Write-Output $_ }

if ($Check) { exit 1 }
exit 0
