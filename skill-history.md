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
- **Commit-Label:** `chore(skill-history): <skill> - <kurzkontext>` mit dem
  Pflicht-Trailer (`AI-Assisted: Codebuff (Buffy)`). Gecomittet wird nur
  `skill-history.md`, nie etwas anderes.
- Vollständige Steuerung: `-NoCommit` (nur Eintrag), `-HistoryFile <pfad>`
  (Override für Tests).

## Einträge

<!-- skill-history:entries-start -->

## session-docs-guardian - 2026-10-01 17:04
- **Kontext/Ausloeser:** Staleness-Audit der Session-Doku: AGENTS-Learning zur Wrapper-Regel, 06-grenzen.md auf P11-Stand (Historie aktiv statt 'auf Zuruf'), Session-Summary gebaut und nach P12 geschlossen; Attribution-Konvention in 10 Dateien umgestellt
- **Umgebung:** Branch `master` @ `2d84e3b`, Host: MaxHambi
- **Quelle:** manuell
- **Ergebnis:** Commits e25f9cc, 9b95377, 6645a8b, ea553aa; bewusst stale gelassen: nichts


## observability-and-instrumentation - 2026-10-01 17:04
- **Kontext/Ausloeser:** Linse ueber den Wrapper-Fix: On-call-Fragen (gelaufen? Ergebnis? Flash?) auf Signale gemappt (LastTaskResult, TaskScheduler-Operational, Runtime-Logs, Selbstpruefung); Luecke = kein Alerting bei Task-Fehlschlag
- **Umgebung:** Branch `master` @ `b191170`, Host: MaxHambi
- **Quelle:** manuell
- **Ergebnis:** Kein Code-Change, Review-Befund in Summary/ADR-014; Alerting als Backlog offen


## agenttrace-session-audit - 2026-10-01 17:04
- **Kontext/Ausloeser:** agenttrace 0.9.0 via Release-Installer nach %LOCALAPPDATA% installiert (go-Pfad veraltet, Projekt ist Rust), User-PATH ergaenzt; --doctor: 8 Sessions (Antigravity-Provider), --overview: Health 85.8, 44/287 Tool-Failures, kein kritisch; Freebuff-Sessions nicht abdeckbar - ehrlich dokumentiert
- **Umgebung:** Branch `master` @ `b5d49a1`, Host: MaxHambi
- **Quelle:** manuell
- **Ergebnis:** Befunde in Session-Summary; Muster spaeter als Advisory-Gate im pre-push-Hook (e658345) verankert


## docs-architect - 2026-10-01 17:04
- **Kontext/Ausloeser:** README-Task-Regel: Wrapper-Muster, Begruendung conhost-vor-Hidden-Schalter, Durchsetzung via install-task.ps1, Verweise auf Audit-Paket und ADR-014
- **Umgebung:** Branch `master` @ `e658345`, Host: MaxHambi
- **Quelle:** manuell
- **Ergebnis:** README-Abschnitt plus ADR-014 gebaut (bde62c9, 33431d3); ToC und docs/index nachgezogen


## onboard (AI Blueprint) - 2026-09-25 05:53
- **Kontext/Ausloeser:** Blueprint 0.12.5 Overlay (AGENTS.md, .agents/, blueprint/) eingecheckt; onboard: Commands/Standards/ai-interaction auf Bun+PowerShell-Stack gesetzt, Attribution-Regel korrigiert; blueprint-CLI 1.10.0 mit @latest nachgezogen (Installer-Versions-Bug)
- **Umgebung:** Branch `master` @ `8d187ba`, Host: MaxHambi
- **Quelle:** manuell
- **Ergebnis:** e15e9a2 + Namenskonvention-Nachtrag; Visibility: Commit; naechster Schritt laut Skill: /overview


## documentation-generation-doc-generate + interview-style-doc-building + code-documentation-doc-generate + brain-to-docs - 2026-09-25 05:46
- **Kontext/Ausloeser:** Doku-Refresh in master: 10 neue Skills in die README-Tabelle (gm mit #20-Verweis nach Nutzerantwort), routed 2.864, USER_GUIDE auf ADR-006-Stand
- **Umgebung:** Branch `master` @ `1ced8e6`, Host: MaxHambi
- **Quelle:** manuell
- **Ergebnis:** Commit auf master, Gate+CI laufen


## skill-writer (evaluation-path + description-optimization) - 2026-09-25 05:41
- **Kontext/Ausloeser:** Audit von session-docs-guardian: Depth-Rubrik 5x pass/1x partial, Should-/Should-not-Trigger-Sets geprueft; Description verbessert (bilinguale Trigger, Artefaktliste inkl. AGENTS.md, Not-for-Grenze, Hook-Verweis) und Docs-only-Staging-Regel ergaenzt
- **Umgebung:** Branch `master` @ `4e82fcf`, Host: MaxHambi
- **Quelle:** manuell
- **Ergebnis:** SKILL.md aktualisiert, routed-Index neu gescannt (2864 Skills)


## github-project-management + team-collaboration-issue - 2026-09-25 05:27
- **Kontext/Ausloeser:** /gm-Skill: Issue #20 angelegt (Supply-Chain-Pinning, Gate-Konflikt zu using-skills, .gitignore fuer .gm/); Duplikat-Bereinigung in ~/.claude/skills - 7 Installer-Kopien (gm, gm-continue, polaris-*, wfgy-method, fifth-dimension-engine, agent-memory) und veraltete github-workflow-automation-Kopie durch Symlinks ersetzt (Write-through verifiziert, Backup unter ~/.claude/skills-backup)
- **Umgebung:** Branch `master` @ `72ea791`, Host: MaxHambi
- **Quelle:** manuell
- **Ergebnis:** Issue #20 ready-for-agent; Konvention '.agents/skills als Single Source' wiederhergestellt - verbleibende echte Kopien in .claude/skills sind Claude-eigene Skills ohne .agents-Gegenstueck


## git-pr-workflows-git-workflow + git-pr-workflows-pr-enhance - 2026-09-25 05:16
- **Kontext/Ausloeser:** ADR-006-PR #18: Branch, Conventional Commits, Pre-Push-Gate, pr-enhance-Description, Squash-Merge
- **Umgebung:** Branch `master` @ `c48c663`, Host: MaxHambi
- **Quelle:** manuell
- **Ergebnis:** PR #18 gemerged (d35353e), CI 6/6 gruen, Master synchron


## team-collaboration-issue + github-project-management - 2026-09-25 05:16
- **Kontext/Ausloeser:** Issue-Bereinigung nach ADR-006: #3-#5/#8-#10 wontfix, #7 completed, #1 superseded, #6 Backlog; SkillSpector-Issue #19 angelegt
- **Umgebung:** Branch `master` @ `5fe9601`, Host: MaxHambi
- **Quelle:** manuell
- **Ergebnis:** Issue-Map sauber: 6x wontfix, 2x completed/superseded, #6 + #14-#17 offen; #19 ready-for-agent


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
