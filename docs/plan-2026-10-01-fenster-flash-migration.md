# Plan: Fenster-Flash-Migration Rest-Tasks + Merge + Historie (2026-10-01, rev. 1 - Blueprint)

> **ABGESCHLOSSEN 2026-10-01** - Slices 0-7 erledigt; PRs #66 (Fix) und #67
> (CI-Lockfile-Fix) squash-gemerged; Rest-Migration 4/4 Tasks live; Historie
> aktiv; Selbstpruefung 22/22 PASS; /complete archiviert unter
> `blueprint/history/fixes/2026-10-01-scheduled-task-window-flash.md`.
> Diese Datei bleibt als historische Referenz an dieser Stelle.

> **Quelle:** Operator-Auftraege vom 01.10.2026 (Chat): Merge des Watchdog-Fixes,
> Migration der uebrigen vier Tasks, Aktivierung der TaskScheduler-Historie,
> Feature-Abschluss. Ausloeser: erneuter Flash gegen 12:34.
> **Vorgaenger:** `audit/2026-10-01-fenster-flash/` (Watchdog-Fix, 3 Commits auf
> `fix/task-window-flash`: `78f9890` Fix, `cb2e4d8` Audit, `d86c735` Spec-Closure).
> Dieser Plan bleibt bis zum Abschluss (Slice 7) an dieser Stelle; Aenderungen
> nur als eigener Commit mit Begruendung.
>
> **Blueprint-Regel:** Jeder Slice ist cold-start-faehig. Ein frischer Agent
> (oder der Operator selbst) fuehrt den Slice ohne Sitzungshistorie aus; alle
> noetigen Pfade, Befehle, Beweise und Rollbacks stehen im Slice. Jeder Slice
> endet mit Artefakten, die ohne KI pruefbar sind (Erweiterung von
> `audit/2026-10-01-fenster-flash/05-selbstpruefung.md` + `99-selbstpruefung.ps1`).

## Ausgangsbefunde (bewiesen am 01.10.2026, read-only)

- Watchdog-Fix wirkt: `12:30:01`-Lauf des "Node Watchdog" via `wscript.exe`
  (Action-Check), `LastTaskResult 0x0`, Logzeile fehlt nicht.
- **Neuer Flash ~12:34 bewiesen:** Um `12:30:01` lief parallel **MemoryIngest**
  noch mit **direktem `powershell.exe`** (LastRun-Check 12:34 Uhr). 4-h-Intervall
  (`04:30 / 08:30 / 12:30 / 16:30 / 20:30 / 00:30`) -> MemoryIngest ist der
  aktuell aktive zweite Blitzer.
- Gleicher Defekt (direktes PowerShell) bei `NpmCleanup` (03:00), `ToolingCleanup`
  (04:00) und `RoutedWatch` (AtLogon, letzte Ausfuehrung 10:49).
- TaskScheduler-Historie ist deaktiviert (Audit P7) -> Vorfaelle bis zur
  Aktivierung nur ueber LastRun/Log-Raster beweisbar.

## Workflow-Geruest (gilt fuer alle Slices)

1. Arbeitsbranch `fix/task-window-flash` (existiert); Slice 1 merged ihn; alle
   weiteren Slices laufen auf `master` nach Pull.
2. Beweis-Artefakte je Slice nach `audit/2026-10-01-fenster-flash/02-beweise/migration/`.
3. Conventional Commits (`fix(tasks): ...`, `docs(audit): ...`, `chore(ops): ...`)
   mit Trailer `AI-Assisted: Codebuff (Buffy)`;
   nur slice-zugehoerige Pfade stagen, keine Sammel-Commits.
4. Nach jedem Code-/Repo-Slice: `npm run verify` muss gruen sein.
5. Rollback je Slice separat ausgewiesen; VORHER-XMLs sind die Rueckkehrebene.

## Slices (Reihenfolge verbindlich; Parallelitaet in Klammern)

### Slice 0 - Plan-Datei (dieser Commit)
- [x] Blueprint als `docs/plan-2026-10-01-fenster-flash-migration.md` abgelegt
- [x] Commit auf `fix/task-window-flash` (`docs(plan): ...`)
- Beweis: Commit-SHA + Plan-Datei im Repo.

### Slice 1 - Merge des Fix via PR (Squash) [vor allem anderen]
- [x] `git push -u origin fix/task-window-flash`
- [x] PR #66 erstellt (Titel im Commit-Format, Summary/Verification/Checklist)
- [x] CI: Test-Matrix rot wegen geerbtem bun.lock-Drift (PR #33-Folge) -> Root-Cause bewiesen (PR-Diff ohne Dep-Aenderungen), Folge-PR #67 (bun.lock-Sync) voll gruen (6/6 Checks) und squash-merged
- [x] PR #66 squash-merged (`3a42512`), Branch geloescht, master gepullt
- Beweis: PR-URLs #66/#67, Merge-SHA `3a42512`/`762ccd0`.

### Slice 2 - MemoryIngest auf Wrapper (hoechste Prioritaet: aktiver Blitzer)
- [x] VORHER-XML gesichert, XML-Round-Trip via migrate-tasks.ps1, Repo-Backup neu
- Beweis: `Exec=wscript.exe`, State=Ready (migration-livecheck.txt).

### Slice 3 - NpmCleanup + ToolingCleanup auf Wrapper
- [x] Beide migriert (gleicher Mechanismus, keine Extra-Argumente)
- Beweis wie Slice 2.

### Slice 4 - RoutedWatch auf Wrapper
- [x] Stop vor Patch (war Running), XML-Round-Trip, Neustart
- Beweis: State=Running (0x41301), Watch-Log 13:13:13 PID 24580.

### Slice 5 - TaskScheduler-Historie aktivieren
- [x] `wevtutil set-log ... /enabled:true` (Admin-Erhoehung, Operator-approved)
- Beweis: get-log `enabled: true`; Events fliessen (13:20:01 Watchdog-Lauf).

### Slice 6 - Selbstpruefung erweitern + Audit-Schluss
- [x] `99-selbstpruefung.ps1` um Pruefungen 7 (Rest-Migration) + 10 (Historie) ergaenzt
- [x] Ausdruck 22/22 PASS als `02-beweise/migration/selbstpruefung-22pass.txt`
- [x] Protokoll-Nachtrag P11 im Audit

### Slice 7 - Feature-Abschluss (/complete)
- [x] Spec archiviert: `blueprint/history/fixes/2026-10-01-scheduled-task-window-flash.md`
- [x] `current-feature.md` auf Stub zurueckgesetzt
- [x] CHANGELOG `[Unreleased]` aktualisiert (Rest-Migration + Historie)
- [x] Plan-Datei als ABGESCHLOSSEN markiert (in-place, mit Beweis-SHAs)
- [x] MemPalace-Drawer `drawer_freebuff_dev_setup_decisions_58029043d55400f980d99d2d` + KG-Fakt `t_..._task_actions_require_wrapper_...` (Identity maxhambi:freebuff:freebuff-dev-setup)
- [x] Abschluss-Commit `f319d5a`; Push steht aus (separates Operator-OK)

## Auditierbarkeits-Matrix

| Slice | Artefakt | Pruefung ohne KI |
|---|---|---|
| 1 | PR-URL, Merge-SHA | `gh pr view`, `git log` |
| 2-4 | VORHER/NACHHER-XMLs je Task + `task\`-Backups | XML-Diff, `Get-ScheduledTask ... Actions[0].Execute` |
| 5 | Log-Status + Event-Dump | `wevtutil get-log`, `Get-WinEvent` |
| 6 | Erweiterter Selbstpruef-Ausdruck | `pwsh -File 99-selbstpruefung.ps1` (read-only) |
| 7 | History-Datei, CHANGELOG, MemPalace-Drawer | Datei-Lektuere, `mempalace search` |

## Explizit unangetastet

Watchdog-Logik/Intervalle · Trigger-/Settings-Blöcke aller Tasks (byte-identisch
uebernommen) · Drittanbieter-Tasks (cua-driver-serve, Hermes_Gateway, MiTeC,
OneDrive, PowerToys) · deskreen-Repo
