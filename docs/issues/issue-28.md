# #28: Freebuff-MCP-Anbindung mempalace — freigeschaltet (globaler Pfad, ADR-010)

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#28](https://github.com/MaxHambi/freebuff-dev-setup/issues/28).
> Label: `ready-for-human`. Status: **closed (2026-09-29)**.

## Ergebnis

mempalace ist nativ freigeschaltet. Der ursprünglich angenommene Weg (Consent-
Prompt für die Projekt-`.mcp.json`) existiert in der Freebuff-UI nicht; der
reale Weg ist in **ADR-010** dokumentiert und wurde komplett durchlaufen:

1. **Deklaration:** mempalace über den UI-Add-Button hinzugefügt → Freebuff
   schreibt den Block nach `~/.agents/mcp.json` (Hash `1902aeee…` →
   `b43adf56…`).
2. **Freigabe:** Operator startete Freebuff neu und erteilte die Freigabe
   (45 Tools); der Attestierungs-Ledger `~/.freebuff/mcp.json` erhielt
   daraufhin den Eintrag (`c7b542f82dac…`, `enabled: true`, generation 2,
   **45 allowedTools**, mtime 2026-09-29 04:21 UTC).
3. **Nativ-Verifikation in der Freebuff-Session:** `mempalace_search`,
   `mempalace_event_list`, `mempalace_add_drawer` — alle mit Provenance
   `serverId c7b542f82dacd0983ae35e9870b544f5` (Ledger-Key-Match).
4. **Diagnose:** `check-mempalace [1/3] Consent OK | [2/3] Binary OK | [3/3] Suche OK` → **Exit 0 (GRUEN)**.

## Beweiskette (warum der alte Weg nicht existierte)

- `configKey`-Mapping des Ledger-Imports vom 24.09.: supabase/rayrun/synapse/
  routed/claimidx = exakt `~/.agents/mcp.json` → Freebuff importiert global,
  scannt die Projekt-Datei nicht.
- Mtime-Koppelung beider Dateien innerhalb 4 ms am 24.09. 01:55 →
  synchroner Import-Vorgang.
- UI-Add-Experiment 29.09.: Button schrieb nach `~/.agents/mcp.json`,
  Ledger byte-identisch → Freebuff liest UND schreibt den globalen Pfad.
- Operator-Befund: UI hat nur allgemeine Connector-Einstellungen, kein
  Projekt-MCP.

## Checkliste (final, korrigierter Weg)

- [x] mempalace über den UI-Add-Button hinzugefügt (schreibt
      `~/.agents/mcp.json`)
- [x] Freebuff neu gestartet + Freigabe erteilt (45 Tools)
- [x] `pwsh -File memory-ingest/check-mempalace.ps1` → **Exit 0 (GRUEN)**
- [x] Nativ-Verifikation search/event_list/add_drawer (Provenance-Match)
- [x] Mirror auf realen Weg umgeschrieben; Diagnose-Hinweis korrigiert
      (#56); ADR-010 dokumentiert den Weg dauerhaft

## Related

- ADR-010 (Weg + Beweiskette), ADR-008 (STDIO-Fallback bleibt Resilienz),
  ADR-009 (Projekt-`.mcp.json` bleibt Fallback für andere Harnesses)
- #29 (Nativ-Verifikation), #31 (Drawer/KG-Ergänzung)
