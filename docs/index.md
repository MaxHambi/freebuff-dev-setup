# Doku-Landkarte: freebuff-dev-setup

Einstieg fuer Menschen und Agenten. Lesereihenfolge je nach Ziel.

## Fuer Agenten (zuerst lesen)

| Datei | Zweck |
|-------|-------|
| `AGENTS.md` (Root) | Konventionen, Commands, Attribution - verbindlich |
| `skills-manager/AGENTS.md` | Ordner-Kontext Skills-Manager (Bun-only, Test-Seams, State-Regeln) |
| `memory-ingest/AGENTS.md` | Ordner-Kontext Memory-Ingest (Read-only-Contract, Live-Schutz, State-Regel, Idempotenz) |
| `docs/agents/issue-tracker.md` | GitHub Issues als Tracker, `gh`-Workflows |
| `docs/agents/triage-labels.md` | Label-Vokabular (`ready-for-agent` etc.) |
| `docs/agents/domain.md` | Domain-Vokabular und Consumer-Regeln |
| `docs/issue-fibel.md` | Issue-Layouts, Label-Statusuebergaenge, Handoff-Regeln (Schwester der Worktree-Fibel) |

## Architektur-Entscheidungen (ADRs)

| ADR | Thema | Status |
|-----|-------|--------|
| `docs/decisions/ADR-001-watchdog-test-known-fails.md` | 4 Known-Fails im Watchdog-Test-Harness (Deep-RCA) | Offen, Verifikation als Issue #14 |
| `docs/decisions/ADR-002-routed-index-single-source.md` | routed-Indexierung: MCP `scan_skills` massgeblich | Accepted |
| `docs/decisions/ADR-003-one-worktree-per-issue.md` | Worktree-Strategie: master-first, temporaer, Issue-first | Accepted |
| `docs/decisions/ADR-004-skills-manager-testing-seams.md` | Zwei Test-Seams (Lib + TUI-Renderer) | Accepted |
| `docs/decisions/ADR-005-mirror-not-move.md` | Skills-Bibliothek: Mirror statt Umbau | Accepted |
| `docs/decisions/ADR-006-externe-skill-manager-tools.md` | TUI-Eigenbau verworfen: skill-manager + SkillSpector statt Slices #3–#10 | Accepted |
| `docs/decisions/ADR-007-memory-ingest-scheduled-task.md` | Memory-Ingest als Scheduled Task (Staleness-Live-Schutz, State-Inkrement, Idempotenz am Quellpfad) | Accepted |
| `docs/decisions/ADR-008-mempalace-cli-fallback-diagnose.md` | MemPalace ohne MCP-Consent: CLI-/STDIO-Fallback + Diagnose-Gate (Exit 0/1/2) | Accepted |
| `docs/decisions/ADR-009-mcp-json-projektlokal.md` | `.mcp.json` bleibt projekt-lokal: gitignore + Index-Entfernung statt Team-Commit | Accepted |

## Skills-Manager (`skills-manager/`)

Einstieg: `skills-manager/docs/INDEX.md`. Darunter:

| Datei | Zielgruppe |
|-------|------------|
| `docs/PRD.md` | Stakeholder - Problem, Analyse-CLI-Scope (nach ADR-006) |
| `docs/PROCESS.md` | Contributor - Issue-Map mit Status nach ADR-006, Git-Workflow |
| `docs/ARCHITECTURE.md` | Contributor - Module, Datenfluss, Regeln |
| `docs/API.md` | Contributor - Lib-Signaturen |
| `docs/USER_GUIDE.md` | Nutzer - CLI, Badges, Troubleshooting |

## Betrieb (Windows-Tasks)

| Datei | Zweck |
|-------|-------|
| `plan.md` | Masterplan Slices T1–T7 (T1 erfuellt, Rest offen) |
| `README.md` | Deploy-Pipeline, Watchdog, Memory-Ingest, Skills-Architektur, MCP-Details |

## Betrieb (Memory-Ingest)

| Datei | Zweck |
|-------|-------|
| `memory-ingest/lib.ts` | Pure Kernlogik (Transcript-Komposition, Export-Planung, State) - ADR-004-Test-Seam |
| `memory-ingest/export.ts` | CLI: inkrementeller Session-Export (read-only DB, Live-Schutz, State) |
| `memory-ingest/ingest.ps1` | Orchestrator: export → `mempalace mine` → optionaler Such-Selbsttest |
| `memory-ingest/test/lib.test.ts` | 16 Unit-Tests gegen tmp-Fixtures |
| `README.md` (Abschnitt "Memory-Ingest") | Betrieb, Live-Schutz, Idempotenz, Wartung |

## Verlauf

| Datei | Zweck |
|-------|-------|
| `docs/sessions.md` | Session-Summaries (was wann geliefert wurde) |
| `docs/worktree-fibel.md` | Worktree-Kurzguide (wann/wie/weg, passend zu ADR-003) |
| `CHANGELOG.md` | Aenderungen nach Keep a Changelog |
