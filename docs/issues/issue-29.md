# #29: Nacharbeit: mempalace_*-Tools nach Freigabe live verifizieren

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#29](https://github.com/MaxHambi/freebuff-dev-setup/issues/29).
> Label: `ready-for-agent`. Status offen, **blocked by #28**.

> **Re-Scope 2026-09-29 (ADR-010):** Der Consent-Weg hat sich geändert —
> Freigabe erfolgt nach Freebuff-Neustart fuer den global registrierten
> Server (`~/.agents/mcp.json`), nicht via Projekt-`.mcp.json`-Prompt.
> STDIO-Verifikation der drei Schluessel-Tools ist bereits erfolgt
> (ADR-008-Transport); hier aktualisiert.

## Parent / Blocked by

Blocked by #28 (Operator: Freebuff-Neustart + Freigabe des Tool-Katalogs).

## Was zu tun ist

Die mempalace_*-MCP-Tools (45 Tools) laufen bis zur Freigabe bewusst ueber
den STDIO-Binary-Pfad (ADR-008). Nach #28 in einer frischen Freebuff-Session
live ueber die **native** Tool-Registrierung gegenpruefen.

## Acceptance Criteria

- [x] **STDIO-Transport (erledigt 2026-09-29, vor der Freigabe):**
      `mempalace_search` OK (Treffer, Schema-konform),
      `mempalace_event_list` OK (Inbox leer = konsistent),
      `mempalace_kg_query` OK (Parameter heisst `entity`; 0 Facts fuer
      Test-Entity = konsistent). Transport ist nicht nativ — dient als
      Baseline.
- [ ] In einer neuen Freebuff-Session (nach Restart + Freigabe) listet die
      Tool-Registrierung mind. `mempalace_search`, `mempalace_add_drawer`
      und `mempalace_event_list`
- [ ] Test-Suche („skill designer eval ranking") laeuft erfolgreich **ueber
      das native MCP-Tool** (nicht CLI/STDIO) und zeigt Decision-Drawer
- [ ] `pwsh -File memory-ingest/check-mempalace.ps1` liefert Exit 0
- [ ] Ergebnis in Mem-Palace.md (Abschnitt MCP-Anbindungen) auf „live
      verifiziert" gesetzt

## Nicht-Ziel

Keine Umstellung bestehender Workflows — der CLI-/STDIO-Fallback bleibt als
Resilienz-Pfad bestehen (ADR-008, durch ADR-010 bestaetigt).
