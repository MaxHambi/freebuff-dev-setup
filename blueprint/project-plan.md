# Project Plan — freebuff-dev-setup (Tasks & Watchdogs als Code)

> Was & Warum. Quelle der Wahrheit fuer den Zweck des Projekts; die
> Feature-/Arbeitsliste lebt in `build-plan.md`. Zuletzt aktualisiert
> 2026-09-29 (Struktur- und Ordnungs-Mission).

## 1. Problem

Der Windows-Entwicklungsrechner lief gestreute, handgepflegte Automatisierungen:
Scheduled Tasks zeigten auf verstreute Pfade (`%LOCALAPPDATA%`, `D:\workspace`),
XML-Backups fehlten, und das Agenten-Gedaechtnis (MemPalace) wurde unregelmaessig
und ohne Live-Schutz gepflegt. Defekte Tasks waren nicht wiederherstellbar,
Leftover-Prozesse blockierten Ports, und Session-Wissen ging verloren.

Dieses Repo macht die Betriebsautomatisierung als Code nachvollziehbar und
wiederherstellbar: definierte Skripte, deployte Runtime, Task-Backups als XML
und ein Ingest-Pipeline fuer das Agenten-Gedaechtnis.

## 2. Users

- **Operator (Max Hambi):** betreibt den Rechner und die Tasks; braucht
  Verlaesslichkeit, Wiederherstellbarkeit und klare Doku.
- **Agenten-Sessions (Freebuff/Codex/Claude, via AGENTS.md-Adapter):**
  arbeiten in diesem Repo; brauchen Konventionen, Gates, Skill-Layout und
  MemPalace-Regeln, um konsistent zu handeln.

## 3. Features (MVP-Kern)

- **Node-Watchdog:** killt nachweisliche `node`/`electron`/`esbuild`-Leftovers
  (Orphan, Idle-Aged, Stale-Port) inkl. Prozessbaum, DryRun-Default.
- **Task-Konsolidierung:** alle eigenen Scheduled Tasks auf
  `%USERPROFILE%\.tools`, XML-Backup je Task.
- **Memory-Ingest:** Session-Transcripte inkrementell ins MemPalace
  (Live-Schutz, State-Inkrement, Idempotenz).
- **Quality-Gate:** `npm run verify` als Pre-Push-Pflicht (Lint, tsc,
  Syntaxcheck, Konventions-Waechter, Tests, Drift-Checks).
- **Doku-/Skills-Ordnung:** ADRs, Issue-Mirror mit Sync-Header, Repo-Skills
  auf Blueprint-Workflow + git/gh/github-Set beschraenkt (ADR-012).

## 4. Data

- **Task-XMLs (`task/`):** exportierte Scheduled-Task-Definitionen
  (Wiederherstellbarkeit; Ruflo-XML = bewusstes Archiv).
- **Whitelist (`node-watchdog/whitelist.txt`):** Substring-Muster gegen
  CommandLine/ExecutablePath.
- **Ingest-State (`memory-ingest-state.json`):** Inkrement-Zeiger je Thread
  (Gitignored, neben dem Export-Ordner).
- **Issue-Mirror (`docs/issues/`):** GitHub-Bodies gespiegelt, Zeile 2 traegt
  `mirror-sync`-SHA-Header (skriptgeprueft).
- **MemPalace-Palast:** Drawers/KG ausserhalb des Repos (ADR-007/008/010/011).

## 5. Tech

- **PowerShell (pwsh):** Watchdog, Deploy/Task-Helper, Tests, Diagnose.
- **Bun/TypeScript:** skills-manager (Analyse-CLI), memory-ingest
  Export/State (lib.ts = pure Test-Seam nach ADR-004).
- **GitHub + gh CLI:** Tracker, Issues, PRs, Mirror-Integritaet.
- **MemPalace:** Agenten-Gedaechtnis (CLI + MCP), Wing `freebuff_dev_setup`.
- **Scheduled Tasks:** Runtime-Betrieb via `%USERPROFILE%\.tools`.

## 6. Monetize

Nicht relevant (persoenliches Infrastruktur-/Workflow-Projekt).

## 7. UI/UX

Kein Produkt-UI. Bedienflaechen sind PowerShell-Skripte (Konsolen-Output mit
klaren Exit-Codes), die nextdns-manager-TUI (eigenstaendiges Modul) und
GitHub-Issues/PRs als Tracker. Doku-UX: `README.md` (Betrieb),
`docs/index.md` (Landkarte), AGENTS.md (Agenten-Konventionen, <100 Zeilen).

## 8. Deployment

- **Runtime:** `%USERPROFILE%\.tools` (Spiegel aus dem Repo via
  `npm run deploy`); Tasks zeigen auf Runtime-Pfade, nie ins Repo.
- **Registrierung:** `npm run install-task` (schtasks bzw. per-user
  Register-ScheduledTask fuer AtLogon), Backup via `npm run export-tasks`.
- **CI:** GitHub-Workflow `ci.yml` (Lint + Syntaxcheck + Bun-Tests +
  Drift-Checks) und `skills-manager.yml`.
- **Gate:** `npm run verify` (Pre-Push-Hook ruft genau diesen Befehl).

## 9. Nicht-Ziele

- nextdns-manager ist ein eigenstaendiges Modul-Projekt im Repo ( eigener
  PLAN, eigene CI-Teile); hier nur Betriebs-Verweise.
- Kein Cross-Platform-Anspruch: Watchdog/Tasks sind Windows-only;
  Tests skippings auf Nicht-Windows.
