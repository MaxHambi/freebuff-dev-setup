# #29: Nacharbeit: mempalace_*-Tools nach Freigabe live verifizieren
<!-- mirror-sync: source=github:MaxHambi/freebuff-dev-setup#29 sha256:bac9d838641f2372675fb1c638a3e367a6f89c1a9066d8eef8a9c9dcb64b94b4 synced=2026-09-29T14:09:06Z -->

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#29](https://github.com/MaxHambi/freebuff-dev-setup/issues/29).
> Label: `ready-for-agent`. Status: **closed (2026-09-29, nativ verifiziert)**.

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

## Acceptance Criteria (final, 2026-09-29)

- [x] **STDIO-Transport (vor der Freigabe):** `mempalace_search` OK
      (Treffer, Schema-konform), `mempalace_event_list` OK (Inbox leer =
      konsistent), `mempalace_kg_query` OK (Parameter heisst `entity`;
      0 Facts fuer Test-Entity = konsistent). Diente als Baseline.
- [x] **Nativ (nach Restart + Freigabe):** Tool-Registrierung der frischen
      Freebuff-Session listet den Server `mempalace` (Provenance `serverId`
      `c7b542f82dacd0983ae35e9870b544f5` = Ledger-Key-Match).
- [x] Test-Suche („skill designer eval ranking") laeuft erfolgreich **ueber
      das native MCP-Tool**: 12 Drawer vor Filter, Rank 1 = Decision-Drawer.
- [x] `pwsh -File memory-ingest/check-mempalace.ps1` liefert **Exit 0
      (GRUEN)**: Consent OK (enabled, generation 2, 45 allowedTools),
      Binary OK, Suche OK.
- [x] Ergebnis in Mem-Palace.md (Abschnitt MCP-Anbindungen) auf „live
      verifiziert" gesetzt (mit ADR-010-Verweis).
- [x] Zusaetzlich nativ verifiziert: `mempalace_event_list` (leere Inbox,
      konsistent) und `mempalace_add_drawer` (Nachweis-Drawer
      `drawer_freebuff_dev_setup_milestone_6b67635181721a921ea87592`,
      room milestone).

## Nicht-Ziel

Keine Umstellung bestehender Workflows — der CLI-/STDIO-Fallback bleibt als
Resilienz-Pfad bestehen (ADR-008, durch ADR-010 bestaetigt).
