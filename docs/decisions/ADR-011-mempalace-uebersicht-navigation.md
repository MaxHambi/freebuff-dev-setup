# ADR-011: MemPalace-Selbstbeschreibung — Uebersicht + Navigations-Drawer

## Status

Accepted

## Date

2026-09-29

## Context

Frische Agent-Threads wissen nicht, **was** im MemPalace-Palast liegt. Die
AGENTS.md (mempalace-shared-brain-Block) erklaert nur das **Wie** (Recall-
Protokoll, Identity, Drawer-/KG-Konvention), nicht den Inhalt. Ein neuer
Agent muss blind suchen (`mempalace search "<vermuteter Begriff>"`) und
braucht Ortskenntnis; Stalheit der Uebersicht droht, wenn der Palast
schneller waechst als die Doku.

Fakten:

- Wing `freebuff_dev_setup`, ueber 1000 Drawers, Rooms u. a. `problem`,
  `documentation`, `milestone`.
- Session-Transcripts laufen via Scheduled Task `MemoryIngest` (ADR-007)
  automatisch in den Palast.
- ADR-Spiegel und Mission-Drawer wurden manuell gefiled (ADR-008-STDIO-Weg
  bzw. CLI-Fallback).
- Die Bestandsdoku `docs/mempalace-regeln.md` ist verbindlich, aber
  regel- und nicht inhaltsorientiert.

## Decision

1. **Zwei-Schichtiges Modell:**
   - **Datei `docs/mempalace-uebersicht.md`** = Inhaltsverzeichnis des
     Palasts (Wing, Rooms, Drawer-Kategorien, Suchbeispiele, Ablage-Regeln).
     Sie ist der menschen- und agentenlesbare Einstieg und wird aus der
     AGENTS.md referenziert (ausserhalb des kanonischen Shared-Brain-Blocks,
     der unangetastet bleibt).
   - **Navigations-Drawer „Palast-Index"** (room `documentation`) = ein
     kompakten Drawer im Palast selbst, der auf die Uebersichts-Datei
     verweist und die wichtigsten Suchbegriffe nennt. Damit findet ein
     blinder Agent mit einer einzigen plausiblen Suche
     (`mempalace search "Palast-Index"`) den Einstieg.
2. **Pflege-Regel:** Bei jeder neuen Drawer-Kategorie (neues thematisches
   Feld, nicht einzelne Drawers) wird die Uebersicht ergaenzt und der
   Palast-Index-Drawer neu gefiled (Neu-Ablage ersetzt den alten Stand
   inhaltlich; Suche liefert beide, der neuere fuehrt).
3. **Keine automatische Synchronisation:** Die Uebersicht ist kuratiert,
   nicht vollstaendig. Der Memory-Ingest (ADR-007) fuellt den Palast,
   nicht die Uebersicht; veraltetes Detail dort ist unkritisch, solange
   die Kategorien stimmen.

## Alternatives Considered

### Vollstaendiger Maschinen-Export des Palasts als Datei
- Pros: immer aktuell
- Cons: gross, schnell stal, redundant zum Palast selbst; Pflegeaufwand ohne
  Gegenwert
- Rejected

### AGENTS.md-Block um Inhaltsliste erweitern
- Pros: alles an einem Ort
- Cons: der kanonische Shared-Brain-Block ist re-rendered
  (`mempalace rules --host ... --harness ...`) und wuerde bei jedem
  Re-Render ueberschrieben; der Block ist bewusst nicht der Ort fuer
  Projekt-Inhalte
- Rejected

### Nur der Drawer ohne Datei
- Pros: eine Quelle
- Cons: Drawer-Text ist klein; Suchende brauchen die ausfuehrliche Datei mit
  Suchbeispielen und Regeln; menschliche Nutzer haben gar keinen Drawer-Zugang
- Rejected

## Consequences

- Neuen Agenten genuegt eine Suche nach „Palast-Index", um Ort und Ablage-
  regeln zu finden; menschliche Leser starten ueber AGENTS.md → Uebersicht.
- Pflicht bei neuen Kategorien: Uebersicht + Index-Drawer aktualisieren
  (kleiner, eingegrenzter Aufwand).
- Die Uebersicht verlinkt `docs/mempalace-regeln.md` (Regeln) und
  `docs/decisions/ADR-008-...` (Fallback/Diagnose) statt sie zu wiederholen.

## Related

- `docs/mempalace-uebersicht.md` (das Inhaltsverzeichnis)
- `docs/mempalace-regeln.md` (verbindliche Regeln)
- ADR-007 (Memory-Ingest), ADR-008 (CLI-/STDIO-Fallback), ADR-010
  (Freebuff-MCP-Pfad)
- `docs/plan-2026-09-29-ready-for-human.md` (Slice 1)
