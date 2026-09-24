# Skills-Manager – Build-Prozess

> Quelle: PRD #1, Slices #2–#10. Dies dokumentiert den festgelegten Ablauf pro Issue.

## Issue-Map

| Slice | Issue | Blockiert von |
|-------|-------|---------------|
| 1 Analyse-CLI (Scan, Klassifizierung, Index & Report) | #2 | – |
| 2 TUI-Baum read-only (Gruppen, Navigation, Beschreibungspanel) | #3 | #2 |
| 3 Multi-Select, Filter & Badges | #4 | #3 |
| 4 Install-Flow (Pfad-Dialog, Copy-Engine, Summary) | #5 | #4 |
| 5 Mirror-Gruppierung (Buckets, routed-Fallback, Dry-Run) | #6 | #2 |
| 6 Delta-Index (inkrementelle Analyse, Move-Erkennung) | #7 | #2 |
| 7 Watcher & Mirror-Sync | #8 | #7, #6 |
| 8 Semantische Suche via routed (`/`) | #9 | #3 |
| 9 TUI-Live-Integration (Watcher-Thread, Rescan) | #10 | #4, #5, #8 |

Parallele Spur möglich: #6 (Mirror) und #7 (Delta-Index) laufen unabhängig; #8 verbindet beide.

## Workflow pro Issue (git-pr-workflows-git-workflow)

Für **jedes Issue**, sobald seine Umsetzung abgeschlossen ist:

1. **Pre-Commit-Review**: Code-Qualität (Stil, Security, Error-Handling), Abhängigkeits- und Breaking-Change-Check der Issue-Änderungen. Kritische/high Findings zuerst fixen.
2. **Tests**: `bun test` (Lib-Tests gegen tmp-Fixtures, Reducer-Tests, TUI-Renderer-Tests je nach Slice) – alle müssen grün sein; Lücken in kritischen Pfaden nachlegen. Danach `npm run lint` (Biome).
3. **Commits**: Conventional Commits (`<type>(skills-manager): <why>`), atomare Commits (~100 Zeilen, Formatierung nie mit Feature mischen), Body erklärt das Warum, Footer mit `Refs #<n>` und der Pflicht-Attribution:
   ```
   🤖 Generated with Codebuff
   Co-Authored-By: Codebuff <noreply@codebuff.com>
   ```
4. **Branch**: kurzer Feature-Branch `feature/skills-manager-<slice>-<thema>` (trunk-based, schnell zurück auf `master`).
5. **Pre-Push-Gate**: `scripts/hooks/pre-push` (Lint/Test) muss durchlaufen – Git-Identity + `core.hooksPath` sind laut AGENTS.md einzurichten, falls noch nicht geschehen.
6. **PR**: Ziel `master`, Description nach dem PR-Enhance-Format (Summary, Detailed Description, Review Checklist, Risk Assessment, Test Coverage, Size Check), Label `ready-for-agent`-Äquivalent nicht nötig – aber `Closes #<n>` im Body, damit der Issue beim Merge schließt. Squash-Merge.

## Definition of Done (pro Issue)

- [ ] Alle Acceptance Criteria des Issues abgehakt
- [ ] Tests + Lint grün (lokal und CI)
- [ ] PR mit vollständiger Description, `Closes #<n>`
- [ ] Keine Secrets/logs/Task-XMLs mit Maschinenpfaden im Diff
