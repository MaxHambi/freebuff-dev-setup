# Skills-Manager – Build-Prozess

> Ausgangsbasis: PRD #1 mit Slices #2–#9. **Stand 2026-09-25 (ADR-006):**
> Die TUI-Entwicklung ist eingestellt – die externen Tools
> [skill-manager](https://github.com/abubakarsiddik31/skill-manager) und
> [SkillSpector](https://github.com/NVIDIA/SkillSpector) übernehmen die
> entsprechenden Funktionen. Diese Map dokumentiert das Schicksal jedes
> Slice; die GitHub-Issues tragen die Kommentare mit ADR-006-Verweis.

## Issue-Map (nach ADR-006)

| Slice | Issue | Status | Grund |
|-------|-------|--------|-------|
| 1 Analyse-CLI (Scan, Klassifizierung, Index & Report) | #2 | ✅ erledigt (PR #12) | gemerged, 25 Tests |
| 2 TUI-Baum read-only | #3 | wontfix | skill-manager (Baum/Navigation) |
| 3 Multi-Select, Filter & Badges | #4 | wontfix | skill-manager (Multi-Select), SkillSpector (Risk statt Badges) |
| 4 Install-Flow | #5 | wontfix | skill-manager (Install aus Collections) |
| 5 Mirror-Gruppierung | #6 | **Backlog (offen, low priority)** | kein externes Äquivalent; Bedarf entscheidet |
| 6 Delta-Index | #7 | ✅ erledigt (PR #12) | alle vier Delta-Kinds mit Tests; Rest-Perf-Ziel ehrlich dokumentiert |
| 7 Watcher & Mirror-Sync | #8 | wontfix | kein Live-Betrieb mehr nötig (manuelles Sichten) |
| 8 Semantische Suche via routed | #9 | wontfix | skill-manager (Suche); routed bleibt via MCP erreichbar |
| 9 TUI-Live-Integration | #10 | wontfix | folgt aus der Einstellung der TUI |

Nachtrag (2026-09-25): SkillSpector-Integration als neue
ai-improvement-Aufgabe (`ready-for-agent`, TDD-Methodik) angelegt.

## Workflow pro Issue (git-pr-workflows-git-workflow)

Für **jedes verbleibende bzw. neue Issue** (z. B. SkillSpector-Integration,
Mirror-Backlog), sobald seine Umsetzung abgeschlossen ist:

1. **Pre-Commit-Review**: Code-Qualität (Stil, Security, Error-Handling), Abhängigkeits- und Breaking-Change-Check der Issue-Änderungen. Kritische/high Findings zuerst fixen.
2. **Tests**: `bun test` (Lib-Tests gegen tmp-Fixtures) – alle müssen grün sein; Lücken in kritischen Pfaden nachlegen. Danach `npm run lint` (Biome) und `bunx tsc --noEmit`.
3. **Commits**: Conventional Commits (`<type>(skills-manager): <why>`), atomare Commits (~100 Zeilen, Formatierung nie mit Feature mischen), Body erklärt das Warum, Footer mit `Refs #<n>` und der Pflicht-Attribution:
   ```
   🤖 Generated with Codebuff
   Co-Authored-By: Codebuff <noreply@codebuff.com>
   ```
4. **Branch**: kurzer Feature-Branch `feature/skills-manager-<thema>` (trunk-based, schnell zurück auf `master`).
5. **Pre-Push-Gate**: `scripts/hooks/pre-push` (Lint/PS-Checks/Tests) muss durchlaufen.
6. **PR**: Ziel `master`, Description nach dem PR-Enhance-Format (Summary, Detailed Description, Review Checklist, Risk Assessment, Test Coverage, Size Check), `Closes #<n>` im Body. Squash-Merge.
7. **CHANGELOG**: `[Unreleased]` bei jedem feat/fix pflegen – der CI-Drift-Check schlägt sonst fehl.

## Definition of Done (pro Issue)

- [ ] Alle Acceptance Criteria des Issues abgehakt
- [ ] Tests + Lint grün (lokal und CI)
- [ ] PR mit vollständiger Description, `Closes #<n>`
- [ ] Keine Secrets/logs/Task-XMLs mit Maschinenpfaden im Diff
