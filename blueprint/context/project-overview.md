# freebuff-dev-setup — Project Overview

> Windows Scheduled Tasks & Watchdogs als Code + Agenten-Gedaechtnis-Pipeline.
> Generiert aus `blueprint/project-plan.md` + `blueprint/build-plan.md`
> (2026-09-29); bei Plan-Aenderungen neu generieren, nicht handeditieren.

## Problem

Der Windows-Entwicklungsrechner lief gestreute, handgepflegte
Automatisierungen: Tasks auf verstreute Pfade, keine XML-Backups, kein
regelmaessiges Agenten-Gedaechtnis. Dieses Repo macht Betrieb als Code
nachvollziehbar: definierte Skripte, deployte Runtime, Task-Backups,
Ingest-Pipeline fuer MemPalace.

## Users

- **Operator (Max Hambi):** betreibt Rechner und Tasks; braucht
  Verlaesslichkeit, Wiederherstellbarkeit, klare Doku.
- **Agenten-Sessions** (via AGENTS.md-Adapter): brauchen Konventionen, Gates,
  Skill-Layout, MemPalace-Regeln fuer konsistentes Handeln.

## Features (in build-plan-Reihenfolge)

1. **Node-Watchdog-Suite** (erledigt) — Kill-Kriterien 1–3, DryRun-Default,
   Whitelist, Baum-Kill; Tests 21/21 nach ADR-001-Closure.
2. **Task-Konsolidierung T2–T4** (erledigt) — alle Tasks auf `.tools`,
   XML-Backups in `task/`; T5/T6 als alte Reste gestrichen.
3. **Memory-Ingest-Pipeline** (erledigt) — inkrementeller Session-Export mit
   Live-Schutz (Staleness-Fenster), State-Inkrement.
4. **MemPalace-Integration** (erledigt) — nativer MCP-Pfad (ADR-010),
   Selbstbeschreibung (ADR-011), Room-Mapping `memory_ingest`.
5. **Quality-Gate + Repo-Hygiene** (erledigt) — `npm run verify` als
   Pre-Push, Konventions-Waechter (Claude-Bann, Mirror-Sync-Header),
   Skills-Layout ADR-012.
6. **Routed-Index-Divergenz klaeren** (offen) — CLI 972 vs. MCP 2843 (#15).
7. **SkillSpector-Integration** (offen) — Risk-Scan-Quelle der Analyse-CLI
   (#19, haengt an 6).
8. **Skills-Sync automatisieren** (offen) — Anbindung + Idempotenz (#17).
9. **gm/gm-continue-Evaluierung** (offen) — Supply-Chain-Pinning (#20).
10. **Session-Doku-Hook** (erledigt 2026-09-29) — bewusst nicht registriert
    (Operator-Entscheid); Doku-Audit läuft skill-getrieben im Session-Closeout.

## Data model

### Task-XML (`task/<Name>.xml`)

- `<Task version="1.2">` (schtasks-Export, UTF-16) — Backup fuer GUI-Import.
- Beziehung: 1 Task-Definition : 1 registrierte Scheduled Task; Pfade zeigen
  auf `%USERPROFILE%\.tools` (Archiv-XML `Ruflo-...` ist die bewusste
  Ausnahme).

### Watchdog-Whitelist (`node-watchdog/whitelist.txt`)

- `pattern` (string, case-insensitive) — Substring-Match gegen
  CommandLine UND ExecutablePath; `#` = Kommentar.
- Beziehung: vom Watchdog gelesen; Override per `-IncludeWhitelisted`.

### Ingest-State (`memory-ingest-state.json`, gitignored)

- `threadId` → `{ updatedAt, lastExportedAt }` — Inkrement-Zeiger je Thread.
- Beziehung: gebunden an den Legacy-Export-Ordner (Idempotenz am Quellpfad,
  ADR-007); `lib.ts` ist der pure Test-Seam (ADR-004).

### Issue-Mirror (`docs/issues/issue-<n>.md`)

- Zeile 2: `<!-- mirror-sync: source=github:...#n sha256:<hex|gone>
  synced=<ISO> -->` — Beweis gegen welchen GitHub-Body-Stand gespiegelt
  wurde; Check im Verify-Gate (`scripts/mirror-sync.ps1 -Check`).
- Beziehung: 1 : 1 zum GitHub-Issue; Repo = Quelle der Wahrheit, GitHub =
  Tracker.

### MemPalace (ausserhalb des Repos)

- Drawers/KG im Wing `freebuff_dev_setup`; Rooms via `mempalace.yaml`
  (gitignored); Identity `maxhambi:freebuff:freebuff-dev-setup`.

## Tech stack

- **PowerShell (pwsh):** Watchdog, Deploy-/Task-Helper, Tests, Diagnose.
- **Bun/TypeScript:** skills-manager (Analyse-CLI, 41 Tests),
  memory-ingest (lib.ts pure Seam, 16 Tests).
- **GitHub + gh CLI:** Tracker/PRs/Mirror.
- **MemPalace:** Agenten-Gedaechtnis (CLI + MCP).
- **Scheduled Tasks:** Betrieb via `.tools`.

## Monetization

Nicht relevant (persoenliches Infrastruktur-/Workflow-Projekt).

## UI/UX

Kein Produkt-UI. Bedienflaechen: PowerShell-Konsolen-Output mit klaren
Exit-Codes, nextdns-manager-TUI (eigenstaendiges Modul), GitHub-Issues/PRs.
Doku-UX: README (Betrieb), `docs/index.md` (Landkarte), AGENTS.md
(Agenten-Konventionen, <100 Zeilen), ROADMAP (`docs/ROADMAP.md`, Slice 8).

## Deployment

- **Runtime:** `%USERPROFILE%\.tools` via `npm run deploy` (Merge-Logik,
  `*.log` wird nie kopiert).
- **Registrierung:** `npm run install-task` (AtLogon per-user via
  Register-ScheduledTask), Backup `npm run export-tasks` → `task/`.
- **CI:** `.github/workflows/ci.yml` + `skills-manager.yml`.
- **Gate:** `npm run verify` (Pre-Push-Hook); zusaetzlich Watchdog-Harness
  (Windows) und `mirror-sync -Check`.

## Open questions

- Route-Trigger der Watchdog-Task: `Get-ScheduledTaskInfo` meldete
  waehrend der RCA `LastTaskResult 2147946720` (0x800710E0, skipped) —
  Verfolgung in Slice 6 (T7-Verifikation).
- Issue-Loeschungen (Slice 8) brauchen den Operator-Entscheid je Kandidat
  (Mirror-first-Regel).
