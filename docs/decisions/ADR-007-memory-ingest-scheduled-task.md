# ADR-007: Memory-Ingest als Scheduled Task statt manuellem Session-Mining

## Status

Accepted

## Date

2026-09-26

## Context

Nach dem Palast-Rebuild (25.09.2026) stammen die fortführenden Erinnerungen
aus dem Legacy-Session-Mining: 4 abgeschlossene Freebuff-Threads wurden
manuell exportiert (`export-freebuff-sessions.ts`) und per
`mempalace mine --mode convos` gefilmt (186 Drawers). Dieser Weg hat vier
Betriebsprobleme:

- **Manuell und vergessensanfällig** — Sessions nach dem 25.09. landen
  nicht im Gedächtnis
- **Live-Schutz war ein Hardcode** (`SKIP_THREAD_IDS` mit fester Thread-ID)
- **Voll-Export bei jedem Lauf** (kein Inkrement)
- **Keine Verifikationsstufe** nach dem Mining

Gleichzeitig gilt: Das Gedächtnis ist nur so gut wie sein jüngster Stand —
Entscheidungen, Probleme und Meilensteine entstehen laufend in Sessions,
nicht in Repo-Dateien.

## Decision

1. **Session-Ingest läuft als Windows Scheduled Task `MemoryIngest`**
   (täglich 04:30, alle 4 h) auf der Runtime-Kopie
   `%USERPROFILE%\.tools\memory-ingest\ingest.ps1` — Pipeline Export →
   `mempalace mine` → optionaler Such-Selbsttest, nach dem Repo-Muster der
   Watchdog-Suite (Deploy-Kopie, `install-task.ps1 -Register`, XML-Backup
   in `task/`).
2. **Live-Schutz per Staleness-Fenster (30 min):** Threads, die jünger
   aktualisiert wurden, bleiben draussen — kein Hardcode mehr.
   `--include-thread` übersteuert bewusst (z. B. für Retrospektiven).
3. **Inkrement über State-Datei** (`memory-ingest-state.json`, bewusst
   **neben** dem Export-Ordner — sonst filmt `mine` sie als
   `_registry`-Junk); Threads unter 2 Nachrichten bleiben draussen.
4. **Export-Ordner bewusst = Legacy-Pfad**
   (`D:/mempalace/exports/freebuff-legacy-sessions`): `mempalace mine` ist
   pro Quellpfad idempotent, gleiche Pfade bedeuten keine Duplikat-Drawers
   (verifiziert: 893 → 894 im ersten Live-Lauf).
5. **`lib.ts` als pure Test-Seam** (ADR-004-Muster): 16 Unit-Tests gegen
   tmp-Fixtures decken Planung, State und Transcript-Komposition ab.

## Alternatives Considered

### Manueller Mining-Aufruf pro Session-Ende (Status quo)
- Pros: Kein neuer Moving Part, User behält volle Kontrolle
- Cons: Vergessensanfällig; genau die Momente, in denen Entscheidungen
  fallen, sind die, die vergessen werden
- Rejected: Automatisierung ist der ganze Sinn des Gedächtnisses

### Daemon/Watcher auf die App-DB (event-getrieben)
- Pros: Minimale Latenz (Ingest Minuten nach Session-Ende)
- Cons: Dauerlaufender Prozess; der node-watchdog würde ihn fressen
  (Orphan/Idle-Kriterien); 4-h-Latenz ist für ein Gedächtnis unkritisch
- Rejected: Batch-Lauf ohne Daemon ist wartbarer und passt zum
  Task-as-Code-Muster des Repos

### Agent fragt am Session-Ende nach ("soll ich minen?")
- Pros: User-Entscheidung pro Session
- Cons: Micro-Consent-Last; Sessions enden oft abrupt (Crash, Restart) —
  genau dann geht der Inhalt verloren
- Rejected: Der Live-Schutz (30 min) macht Nachfragen unnötig

## Consequences

- Neue Sessions landen spätestens nach 4 h im Palast; die laufende Session
  bleibt immer draussen (Staleness-Fenster statt Skip-Liste).
- Ein neuer Moving Part mit Betriebslast: Log-Rotation (5 MB), Task wird
  über die Deploy-Pipeline aktualisiert (`deploy.ps1 -Force` +
  `install-task.ps1 -Register`); Runtime-Logs überschreibt deploy nie.
- Idempotenz hängt am Quellpfad: Der Export-Ordner darf nicht umziehen,
  ohne den Palast zu synchronisieren; der State liegt ausserhalb des
  Mining-Korpus (Vorfall einmalig bereinigt per `mempalace_delete_by_source`).
- Test-Gate erweitert: `bun test` deckt die Ingest-Logik ab (41 Tests
  gesamt).

## Related

- ADR-004 (Test-Seams — `lib.ts` folgt dem Muster)
- ADR-008 (MemPalace-Anbindung/CLI-Fallback — der Ingest läuft bewusst
  CLI-basiert, unabhängig vom MCP-Consent)
- ADR-003 (Issue-first-Regel — dieser Workflow wurde auf direkten
  Sitzungsauftrag ohne vorheriges Issue gebaut; die offenen Folge-Arbeiten
  liegen als Issues #28–#31 vor)
- Mem-Palace.md (Abschnitt Legacy-Session-Mining, automatisiert seit
  26.09.2026)
