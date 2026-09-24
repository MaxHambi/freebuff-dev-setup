# Doku-Landkarte: tools-entwicklung

Einstieg fuer Menschen und Agenten. Lesereihenfolge je nach Ziel.

## Fuer Agenten (zuerst lesen)

| Datei | Zweck |
|-------|-------|
| `AGENTS.md` (Root) | Konventionen, Commands, Attribution - verbindlich |
| `skills-manager/AGENTS.md` | Ordner-Kontext Skills-Manager (Bun-only, Test-Seams, State-Regeln) |
| `docs/agents/issue-tracker.md` | GitHub Issues als Tracker, `gh`-Workflows |
| `docs/agents/triage-labels.md` | Label-Vokabular (`ready-for-agent` etc.) |
| `docs/agents/domain.md` | Domain-Vokabular und Consumer-Regeln |

## Architektur-Entscheidungen (ADRs)

| ADR | Thema | Status |
|-----|-------|--------|
| `docs/decisions/ADR-001-watchdog-test-known-fails.md` | 4 Known-Fails im Watchdog-Test-Harness (Deep-RCA) | Offen, Verifikation als Issue #14 |
| `docs/decisions/ADR-002-routed-index-single-source.md` | routed-Indexierung: MCP `scan_skills` massgeblich | Accepted |
| `docs/decisions/ADR-003-one-worktree-per-issue.md` | Worktree-Strategie: master-first, temporaer, Issue-first | Accepted |
| `docs/decisions/ADR-004-skills-manager-testing-seams.md` | Zwei Test-Seams (Lib + TUI-Renderer) | Accepted |
| `docs/decisions/ADR-005-mirror-not-move.md` | Skills-Bibliothek: Mirror statt Umbau | Accepted |

## Skills-Manager (`skills-manager/`)

Einstieg: `skills-manager/docs/INDEX.md`. Darunter:

| Datei | Zielgruppe |
|-------|------------|
| `docs/PRD.md` | Stakeholder - Problem, 33 User Stories, Decisions |
| `docs/PROCESS.md` | Contributor - Issue-Map #2–#10, Git-Workflow pro Issue |
| `docs/ARCHITECTURE.md` | Contributor - Module, Datenfluss, Regeln |
| `docs/API.md` | Contributor - Lib-Signaturen |
| `docs/USER_GUIDE.md` | Nutzer - CLI, Badges, Troubleshooting |

## Betrieb (Windows-Tasks)

| Datei | Zweck |
|-------|-------|
| `plan.md` | Masterplan Slices T1–T7 (T1 erfuellt, Rest offen) |
| `README.md` | Deploy-Pipeline, Watchdog, Skills-Architektur, MCP-Details |

## Verlauf

| Datei | Zweck |
|-------|-------|
| `docs/sessions.md` | Session-Summaries (was wann geliefert wurde) |
| `CHANGELOG.md` | Aenderungen nach Keep a Changelog |
