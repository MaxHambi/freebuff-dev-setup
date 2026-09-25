# Skill-History

Changelog jeder Skill-Ausführung in diesem Repo. Ein Eintrag pro gestartetem
Skill, neuester zuerst. Der Eintrag entsteht in der Session (manuell oder über
den PostToolUse-Hook, siehe unten) und wird pro Ausführung als eigener Commit
mit dem Label `chore(skill-history):` versioniert – dadurch bleibt die Historie
der Skill-Nutzung auditierbar, ohne andere Commits zu mischen.

## Eintragsformat

```markdown
## <skill-name> — <JJJJ-MM-TT HH:MM>
- **Kontext/Auslöser:** Was war das Ziel, in welchem Scope wurde der Skill gefahren?
- **Umgebung:** Branch @ Commit, Host
- **Quelle:** manuell | session-hook
- **Ergebnis:** Kurzfazit (Findings, Folge-Commits, offene Punkte)
```

## So wird geloggt

- **Manuell:** `pwsh -File scripts/skill-history-log.ps1 -SkillName "<name>" -Detail "<kontext>" -Ergebnis "<fazit>"`
- **Session-Hook:** `.claude/settings.json` registriert den Aufruf als
  PostToolUse-Hook für das Tool `Skill`; das Hook-JSON (stdin) liefert
  Skill-Name und Argumente automatisch. Fehler blockieren nie die Session
  (Exit 0).
- **Commit-Label:** `chore(skill-history): <skill> - <kurzkontext>` mit der
  Pflicht-Attribution (`Co-Authored-By: Codebuff`). Gecomittet wird nur
  `skill-history.md`, nie etwas anderes.
- Vollständige Steuerung: `-NoCommit` (nur Eintrag), `-HistoryFile <pfad>`
  (Override für Tests).

## Einträge

<!-- skill-history:entries-start -->

## review-swarm — 2026-09-25 11:20
- **Kontext/Auslöser:** Nach Arbeitsaufnahme Read-Only-Review über die zuletzt gemergten PRs #11 (using-skills), #12 (Skills-Manager Slice 1) und #13 (node-watchdog T1) mit vier Rollen (Intent/Regression, Security/Privacy, Performance/Reliability, Contracts/Coverage).
- **Umgebung:** Branch `master` @ `17817ca`, Host: MaxHambi
- **Quelle:** manuell
- **Ergebnis:** 5 verifizierte Findings, keine materialen Security/Privacy-Probleme. Fix now: tote package.json-Scripts (`group`/`tui`), CLI-`routed scan` statt MCP `scan_skills` in skills-sync.ps1 (gebunden an Issue #15/#17). Fix soon: Stopword-Heuristik im check-changelog.ts, Watchdog-Portlisten-Doku, Delta-Perf-Ziel aus #7 ehrlich in der Closure dokumentieren.

## using-skills + git-pr-workflows-git-workflow + git-pr-workflows-pr-enhance — 2026-09-25 11:45
- **Kontext/Auslöser:** Session-Arbeit nach Nutzervorgabe: ADR-006 (externe Skill-Manager-Tools statt Eigenbau-TUI), Doku-Bereinigung, Issue-Closures, Commit-/PR-Pipeline nach Conventional Commits mit pr-enhance-Description-Format.
- **Umgebung:** Branch `master` @ `17817ca`, Host: MaxHambi
- **Quelle:** manuell
- **Ergebnis:** Workflow trifft zu (trunk-based, Squash-Merge, Pre-Push-Gate); Umsetzung läuft in dieser Session, Einträge der Folge-Commits siehe Historie.
