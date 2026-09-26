# MemPalace-Regeln für Agenten (verbindlich)

Gilt für jede Session in diesem Repo, zusätzlich zum Shared-Brain-Block in
`AGENTS.md`. Identity überall: `maxhambi:freebuff:freebuff-dev-setup`.

## 1. Recall (Suche vor Antwort)

- Bevor eine Frage über frühere Arbeit, Entscheidungen oder Begründungen
  beantwortet wird: **erst `mempalace search`**, Treffer **wörtlich**
  zitieren (Quelle nennen) - nie paraphrasieren.
- Findet der Palast nichts: sagen, dass er nichts hat. Nicht raten.
- Exakte Begriffe (Skill-Namen, Dateinamen, ADR-Nummern) schlagen
  Prosa-Fragen; bei 0 Treffern Query variieren statt aufgeben.

## 2. Wissen einpflegen (Drawers)

- **Vor dem Filing Duplikat-Check** (`mempalace search` nach dem Thema).
- `room` nach Inhalt wählen: `decision` (Entscheidung + Begründung +
  Konsequenz + **Quellenpfad**), `problem`, `milestone`, `documentation`,
  `task`. Quellenpfad ist Pflichtfeld im Content (Repro der Aussage).
- `added_by` immer mit der vollen Agent-Identity setzen - auch auf dem
  STDIO-Pfad (`mempalace-mcp.exe` via JSONRPC, solange #28 offen ist,
  siehe ADR-008).
- Keine Secrets, Tokens, Passwörter - in Drawers, Events und KG.

## 3. KG-Fakten vs. Freitext-Drawer

| | KG (`mempalace_kg_add`) | Drawer (`mempalace_add_drawer`) |
|---|---|---|
| Geeignet für | **einzelfaktische, supersede-fähige** Zustände (Repo-Name, Identity, laufender Task) | Zusammenhänge, Begründungen, mehrteilige Entscheidungen |
| Wird aktualisiert via | `mempalace_kg_supersede` (nie überschreiben) | Neuer Drawer, alter bleibt (append-only) |

Faustregel: Wenn die Information "gilt bis etwas anderes gilt", gehört sie
ins KG, nicht in einen Freitext-Drawer.

## 4. Ingest (Sessions → Palast)

- Läuft automatisch: Scheduled Task `MemoryIngest` (ADR-007) - nicht
  manuell anstoßen, außer mit Begründung (z. B. `-IncludeThread` für
  Retrospektiven, übersteuert den Live-Schutz bewusst).
- Die **laufende Session wird nie exportiert** (Staleness-Fenster 30 min) -
  das ist eine Invariante, kein Konfigurationsdetail.
- Export-Ordner und State-Lage nicht ändern (Idempotenz am Quellpfad,
  `memory-ingest/AGENTS.md`).
- Repo-Doku (ADRs, Regeln, Issue-Mirror) wird **nicht** vom Task erfasst:
  nach größerer Doku-Arbeit einmalig `mempalace mine D:/freebuff-dev-setup`
  laufen lassen (idempotent). `memory-ingest/*` landet bis #30 in `general`.

## 5. Diagnose & Störung

- Erstverdacht immer: `pwsh -File memory-ingest/check-mempalace.ps1`
  - Exit 0 = alles grün; Exit 2 = nur MCP-Consent fehlt (CLI-Fallback ist
    der sanktionierte Weg, ADR-008); Exit 1 = harter Fehler (Audit lesen:
    `docs/mempalace-audit-2026-09-26.md`).
- Consent niemals manuell in `~/.freebuff/mcp.json` schreiben (#28, ADR-008).

## 6. Logstream (Koordination)

- **Declared-idle**: kein Hintergrund-Watcher bei Session-Start.
- Inbox-Sweep vor Kollaboration/langen Tasks (CLI kennt kein `--preview`!):
  `mempalace logstream list --to-agent maxhambi:freebuff:freebuff-dev-setup --limit 10`
  - gemerkte `id` ist der Cursor für `--since-event-id`.
- Watcher nur bewaffnen (und ankündigen) wenn gehört/delegiert wird -
  Protokoll im `AGENTS.md`-Shared-Brain-Block gilt unverändert.
- Logstream ist immutable: keine Smoke-/Test-Events ohne Freigabe.

## 7. Verweise

- Audit + Befunde: `docs/mempalace-audit-2026-09-26.md`
- Betrieb/Konfiguration: `Mem-Palace.md` (privat)
- ADR-007 (Ingest), ADR-008 (Fallback/Diagnose), ADR-009 (`.mcp.json` lokal)
- Offene Lücken: #28 (Consent), #29 (Live-Verifikation), #30 (`memory_ingest`-Room), #31 (Drawer + KG-Fakten)
