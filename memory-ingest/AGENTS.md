Apply root AGENTS.md first, then this file.

# memory-ingest – Ordner-Kontext (AGENTS.md)

- **Bun-only**: `export.ts`/`lib.ts` laufen und testen nur mit Bun (`bun:sqlite`); Node ist kein Ziel.
- **Read-only-Contract**: Die Freebuff-App-DB (`desktop-v2.db`) wird ausschließlich lesend geöffnet — niemals schreiben, auch nicht "nur einmal zum Testen".
- **Live-Schutz ist eine Invariante**: Threads, deren `updatedAt` jünger als das Staleness-Fenster (Default 30 min) liegt, werden nie exportiert. `--include-thread` übersteuert bewusst und nur auf expliziten Auftrag (ADR-007).
- **State-Datei liegt neben dem Export-Ordner**, niemals darin: `mempalace mine` liest den ganzen Ordner ein und filed den State sonst als `_registry`-Junk (Vorfall 26.09.2026, bereinigt per `mempalace_delete_by_source`).
- **Idempotenz hängt am Quellpfad**: Der Export-Ordner ist bewusst der Legacy-Pfad (`D:/mempalace/exports/freebuff-legacy-sessions`). Umzug = Duplikat-Drawers im Palast; vorher ADR-007 lesen.
- **Test-Seam nach ADR-004**: `lib.ts` ist pure (Planung, State, Komposition) und gegen tmp-Fixtures getestet (`bun test memory-ingest`); IO gehört in `export.ts`, keine DB in Tests.
- **Orchestrierung in PS1**: `ingest.ps1` (Export → mine → Verify) ist das Task-Entry; Runtime-Kopie unter `~/.tools` (deploy.ps1 überschreibt nie `*.log`), Task `MemoryIngest` via `install-task.ps1 -Task MemoryIngest -Register`.
- **Diagnose**: `check-mempalace.ps1` — Exit 0 grün, 1 harter Fehler, 2 = nur MCP-Consent fehlt (bis Issue #28 der Normalzustand, kein Fehlerfall).
