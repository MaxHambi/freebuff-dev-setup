# AGENTS.md – tools-entwicklung

## Projekt
Windows-Tasks & Watchdogs als Code: Scheduled Tasks werden hier versioniert,
nach `%USERPROFILE%\.tools\` deployt und als exportierte Task-XML in `task\`
gesichert (GUI-Wiederherstellung möglich). Referenzplan: `plan.md` (Slices T1–T7).

## Struktur
- `node-watchdog/` – Watchdog-Suite (Kill-Kriterien: orphan, idle-aged, stale port); T1 gemerged, Known-Fails in ADR-001
- `skills-manager/` – Analyse/Klassifizierung/Delta-Index der Skill-Bibliothek (Bun); OpenTUI-Slices als Issues #3–#10
- `skills/` – repo-eigene Agent Skills (`using-skills` Meta-Skill mit Gate-/Sync-Hooks)
- `node-monitor/`, `maintenance/`, `routed-watch/`, `ruflo-policy-rotate/` – migrierte Tasks (Slices T3–T6 offen)
- `task/` – exportierte Task-XMLs (Backup/Wiederherstellung)
- `scripts/` – Deploy- & Registrierungs-Helper
- `docs/decisions/` – ADRs (002–005); Doku-Einstieg: `docs/index.md`, `skills-manager/docs/INDEX.md`

## PowerShell-Konventionen
- Skripte: `pwsh`-kompatibel (PS 7), aber Task-Aktion nutzt Windows-PowerShell 5.1 → keine PS-7-only Features im Task-Pfad
- `Set-StrictMode -Version Latest` + `$ErrorActionPreference = 'Stop'` in jedem Skript
- Kommentare auf Deutsch, keine Emojis in Logausgaben
- Manuelles Testen immer mit DryRun-Parametern vor `-Apply`

## Git Workflow & Versioning (oberste Regel)
- Vor jedem Commit/Push/Branch/Release gilt der Skill **git-workflow-and-versioning**
- Trunk-Based: `master` immer deploybar; kurze Branches (`feature/*`, `fix/*`, `chore/*`)
- Atomic Commits (~100 Zeilen): Formatierung nie mit Feature-Änderungen mischen
- Commit-Format: `<type>: <why-spezifische Beschreibung>` mit `feat|fix|refactor|test|docs|chore`
- Kein Force-Push auf `master`; nie Logs, Task-XMLs mit Maschinenpfaden outside `task/`, oder Secrets committen

## Commit Attribution
AI commits MUST include:
```
Co-Authored-By: Codebuff <noreply@codebuff.com>
```

## Git Identity (nach frischem Clone)
```bash
git config --global user.name "MaxHambi"
git config --global user.email "181495919+MaxHambi@users.noreply.github.com"
gh auth setup-git
git config core.hooksPath scripts/hooks   # Pre-Push-Gate aktivieren
```

## File-Scoped Commands
| Task | Command |
|------|---------|
| Lint (alles) | `npm run lint` |
| Lint einzelne Datei | `npx biome lint <pfad>` |
| Format | `npm run format` |
| PowerShell-Syntaxcheck | `pwsh -NoProfile -Command "[void][ScriptBlock]::Create((Get-Content -Raw '<pfad>'))"` |
| Watchdog-DryRun | `pwsh -File node-watchdog/node-watchdog.ps1` |
| Watchdog-Tests | `pwsh -File node-watchdog/run-tests.ps1` |
| Task-Registrierung | `pwsh -File scripts/install-task.ps1 -Task <name>` |
| Tests (Repo) | `npm test` |
| Tests (Skills-Manager) | `bun test` |
| Typecheck (Skills-Manager) | `bunx tsc --noEmit` |
| Analyse-CLI | `bun run skills-manager/src/analyze.ts` |
| Changelog-Drift-Check | `bun run skills-manager/scripts/check-changelog.ts --base origin/master` |
| Commit-Format-Check | `bun run skills-manager/scripts/check-commits.ts --base origin/master` |

## CI
- `.github/workflows/ci.yml`: Lint (Biome) + PowerShell-Syntaxcheck, ubuntu & windows Matrix
- `.github/workflows/skills-manager.yml`: bun test/lint/typecheck + Conventional-Commits- und CHANGELOG-Drift-Check (nur bei skills-manager-Pfaden)
- Pre-Push-Hook `scripts/hooks/pre-push` erzwingt Lint/Test lokal

## Key Conventions
- Lint/Format ausschließlich **Biome** (`biome.json`); keine ESLint-/Prettier-Konfigs
- Task-XMLs in `task/` enthalten absolute Pfade → nur als Backup, nie als Installationsquelle
- Runtime-Pfade zeigen auf `%USERPROFILE%\.tools\`, nicht ins Repo
- DryRun vor Apply: keine destruktive Aktion ohne vorherigen Report-Run
- Keine Secrets committen (`.env` ignoriert, Vorlage `.env.example`)
- Skills-Bibliothek `~/.agents/skills` ist NUR LESE-Zugriff fuer den Skills-Manager; kein Umbau, Mirror statt Move (ADR-005)
- `skills-manager/src/data/` ist gitignored (generierte Artefakte)
- CHANGELOG `[Unreleased]` bei jedem feat/fix aktualisieren (CI-Drift-Check)
- Worktrees nur temporaer bei parallelen Sitzungen, nach Merge entfernen (ADR-003)
- routed-Indexierung: MCP `scan_skills` ist massgeblich, nicht CLI `routed scan` (ADR-002)

## Agent skills

### Issue tracker

Issues leben in GitHub Issues (MaxHambi/tools-entwicklung, `gh` CLI); PRs sind kein Triage-Surface. Siehe `docs/agents/issue-tracker.md`.

### Triage labels

Fünf kanonische Rollen mit Default-Namen (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). Siehe `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `AGENTS.md` als Vokabular-Quelle, `docs/adr/` für ADRs. Siehe `docs/agents/domain.md`.

## MCP-Server
- `routed` (`.cline/mcp_settings.json`): Skill-Routing, läuft repo-unabhängig; Auto-Approve: `route_skill`, `get_skill`, `list_skills`; `scan_skills` manuell (Index-Rebuild, massgeblicher Weg laut ADR-002)
- Workflow `.cline/workflows/route.md`: `/route <prompt>` vor fachlicher Arbeit
- Session-Ende: Skill `session-docs-guardian` ausfuehren (Doku-Audit + Session-Summary); Hook-Registrierung siehe `~/.agents/skills/session-docs-guardian/hooks/register-hook.md`
