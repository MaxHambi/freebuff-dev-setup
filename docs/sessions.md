# Session-Verlauf

Kurze Summaries pro Session: was wurde geliefert, entschieden, offen gelassen.
Neue Eintraege oben. Detailtiefe lebt in PRs/Issues/ADRs - hier nur Kontext.

## 2026-09-27 - PR #27 gemerged, Rename-Issues geschlossen, Board aufgeraeumt

**Geliefert:** Branch `chore/rename-freebuff-dev-setup` mit 15 Commits
gepusht (Pre-Push-Gate gruen); PR #27 nach Draft-Ready per **Merge-Commit**
gemerged (`8f520f9`, Weg laut Worktree-Fibel fuer mehrschichtige Verlaeufe);
#21-#26 via `Closes`-Keywords automatisch geschlossen (COMPLETED) und mit
ehrlichen Closure-Kommentaren versehen (#24: zwei bewusste Reste -
app-eigener Freebuff-Desktop-Projektpfad in `memory-ingest/export.ts:35`
und historisch korrekter CHANGELOG-Eintrag); #29/#31 vorher auf
`ready-for-agent` + Board-Ready gesetzt. Board-Endzustand: **Done**
1/3/4/5/7/8/9/10/18(PR)/21-26/27(PR), **Ready** 28/29/30/31/32,
**Backlog** 6/14-17/19/20. Issue-Mirror um issue-21 bis issue-26 ergaenzt.
Dashboard zusaetzlich priorisiert: Priority-Feld gesetzt (P0: #28/#30/#32,
P1: #29/#31/#14), Ready-Spalte in P0-first-Reihenfolge sortiert
(28 -> 30 -> 32 -> 29 -> 31).

**Entscheidungen:** Master-Zyklus ohne Feature-Branch nur fuer reine
Doku-Commits (`docs:`), alles Andere ueber Branch + PR. MemPalace-
Loop-Closure festgezurrt: nach Abschluss jedes gelieferten Themas
Decision-Drawer file-en (Rename-Follow-up-Closure-Drawer per STDIO
nach ADR-008 gefiled, Suche Rank 1, Palast 1089 Drawers).

**Offen:** #28 Consent-Freischaltung (`ready-for-human`), #29 Live-
Verifikation (blocked by #28), #30 mempalace.yaml Room-Mapping
(`ready-for-human`), #31 Decision-Drawer + KG-Fakten (AFK-faehig),
#32 Task-Migration T2-T6 (`ready-for-human`).

## 2026-09-27 - Board-Automatisierung: project-mirror-Workflow

**Geliefert:** `.github/workflows/project-mirror.yml` - spiegelt
Issue-Zustaende automatisch ins Dashboard: neue Issues auf Backlog,
`ready-for-*` -> Ready, `in-review` -> In review (hoehste Label-
Prioritaet), Schliessen -> Done, Reopen -> Rueckfall auf Label-Sicht.
E2E-Test mit Wegwerf-Issue #34: Runs gruen, Skip-Guard verifiziert
(warnung statt rotem Run, solange Secret fehlt). Ueberraschung dabei:
#34 landete trotzdem im Board - das Project hat bereits eine
eingebaute Auto-Add-Automatisierung; der Workflow addiert also
primaer die Label-Spiegelung, das Add ist idempotenter Fallback.
Label `in-review`
angelegt (sechstes kanonisches Triage-Label), Fibel +
triage-labels.md um Automatik-Hinweis ergaenzt. Projekt-Move-
Konvention jetzt: Label setzen statt Karte schieben.

**Entscheidungen:** PAT-Voraussetzung bewusst via Repo-Secret
`PROJECTS_PAT` (Classic PAT, Scopes `repo` + `project`), weil
GITHUB_TOKEN repo-skoped ist und user-owned Projects V2 nicht
mutieren darf; Guard macht den fehlenden Zustand sichtbar, statt
zu crashen. Board-Positionen (Sortierung) bleiben manuell
(updateProjectV2ItemPosition-Kette), der Spiegel regelt nur den
Status.

**Offen:** Secret `PROJECTS_PAT` noch nicht gesetzt -> Spiegel
greift erst danach; Label-E2E dann mit einem Wegwerf-Issue
nachholen. #34/#35 (Test-Issues) sind geschlossen; Loeschen per
REST `DELETE /issues/<n>` geht mit dem gh-OAuth-Token nicht (nur
Fine-grained-Token/App) - UI-Loeschung bleibt manuell.

## 2026-09-26 - Memory-Ingest-Workflow, MemPalace-Wiring, ADR-007 bis ADR-009

**Geliefert:** Memory-Ingest-Workflow (`memory-ingest/`: pure lib.ts nach
ADR-004, inkrementeller Export mit Staleness-Live-Schutz, Orchestrator
`ingest.ps1`, 16 Unit-Tests) mit Scheduled Task `MemoryIngest` (04:30 + 4 h,
Task-Lauf Exit 0, XML-Backup in `task/`); Diagnose-Script
`check-mempalace.ps1` (Consent/Binary/Suche, Exit 0/1/2); `install-task.ps1`
kann jetzt wirklich registrieren (`-Register`), `deploy.ps1` schont
Runtime-Logs; `.mcp.json` bewusst lokal (gitignore + Index-Entfernung);
Labels `needs-triage`/`needs-info`/`ready-for-human` angelegt; Issues
#28–#31 in Abhaengigkeitsreihenfolge; 3 Decision-Drawer ins Palast-
Gedaechtnis gefiled (Backup-Loeschung, Legacy-Session-Mining,
Umbenennung) und per Suche verifiziert. Commits e42375c…04cf25c auf
`chore/rename-freebuff-dev-setup`.

**Entscheidungen:** ADR-007 (Memory-Ingest als Scheduled Task statt
manuellem Session-Mining), ADR-008 (MemPalace ohne MCP-Consent:
sanktionierter CLI-/STDIO-Fallback + Diagnose-Gate), ADR-009 (`.mcp.json`
bleibt projekt-lokal).

**Offen:** #28 Consent-Freischaltung (`ready-for-human`), #29 Live-
Verifikation der mempalace_*-Tools (blocked by #28), #30 mempalace.yaml
Room-Mapping (`ready-for-human`, Edit-Tool-Blockade), #31 vierter Drawer +
KG-Fakten; Branch unpushed; `mempalace repair-status` meldet benignen
HNSW-Hinweis (metadata not flushed, Vektor-Suche aktiv).

## 2026-09-25 - ADR-006 (TUI verworfen), Skill-History-Workflow, Issue-Bereinigung

**Geliefert:** Skill-History-Workflow (`skill-history.md` + Hook
`scripts/skill-history-log.ps1`, Session-Hook via `.claude/settings.json`,
eigene Commits mit Label `chore(skill-history)`) - 6477ca2. Review-Swarm
(4 Rollen, read-only) ueber PRs #11-#13: 5 verifizierte Findings, davon
tote package.json-Scripts im ADR-006-PR behoben. PR #18 (ADR-006 + Doku-
Bereinigung, Squash-Merge d35353e). Issues: #3-#5/#8-#10 wontfix, #7
completed (PR #12), #1 superseded, #6 Backlog-Kommentar. Issue #19
angelegt (SkillSpector-Integration, ai-improvement).

**Entscheidungen:** ADR-006 - OpenTUI-Eigenbau eingestellt; extern:
skill-manager (Baum/Multi-Select/Install/Suche) + SkillSpector (Risk-Scan).
Analyse-CLI bleibt Kernstueck, Mirror-Gruppierung (#6) als Backlog.

**Offen:** #6 (Mirror-Backlog), #14-#17 (Watchdog/routed/Sync), #19
(SkillSpector, TDD), Slices T2-T7 aus plan.md.

## 2026-09-24 - Skills-Manager Slice 1 + Multi-Sitzungs-Zusammenfuehrung

**Geliefert:** PR #12 (Analyse-CLI: Scan, Klassifizierung stale/incompat/setup, Delta-Index mit Move-Erkennung, 25 Tests, CI-Workflow mit Commit-/Changelog-Gate), PR #13 (node-watchdog Slice T1, inkl. ubuntu-CI-Fix), PR #11 (using-skills Meta-Skill mit Gate-/Sync-Hooks) - alle gemerged. Issues #14-#17 aus offenen Worktree-Punkten angelegt.

**Entscheidungen:** ADR-002 (routed `scan_skills` massgeblich), ADR-003 (Worktree master-first, temporaer), ADR-004 (zwei Test-Seams), ADR-005 (Mirror statt Move).

**Konvention:** Alle Ordner-Agent-Dateien heissen AGENTS.md (skills-manager/CLAUDE.md entfernt, Root-CLAUDE.md nur lokaler Symlink).

**Offen:** Skills-Manager-Slices #3-#10 (OpenTUI folgt), #14 ADR-001-Closure, #15 routed-Divergenz, #16 Watchdog-Reviewer-Entscheidungen, #17 skills-sync-Regularisierung, Slices T2-T7 aus plan.md.

## 2026-09-24 - Planungsphase Skills-Manager

**Geliefert:** PRD als Issue #1 (33 User Stories), 9 Tracer-Bullet-Slices als Issues #2-#10, Tracker-Konfig `docs/agents/` + AGENTS.md-Block, Label `ready-for-agent` auf GitHub angelegt.

**Entscheidungen:** GitHub Issues statt lokaler Markdown-Files; Test-Seams Lib+TUI-Renderer (User-Wahl); Mirror statt in-place; Copy statt Move; Delta-/Watch-Faehigkeit als Kernanforderung (User-Feedback: Bibliothek wird laufend aufgeräumt).
