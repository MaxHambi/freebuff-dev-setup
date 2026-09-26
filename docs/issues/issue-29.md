# #29: Nacharbeit: mempalace_*-Tools nach Consent live verifizieren

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#29](https://github.com/MaxHambi/freebuff-dev-setup/issues/29).
> Label: `needs-triage`. Status offen, **blocked by #28**.

## Parent / Blocked by

Blocked by #28 (Consent-Freischaltung in der Freebuff-UI).

## Was zu tun ist

Die mempalace_*-MCP-Tools (45 Tools, u. a. mempalace_search,
mempalace_add_drawer, mempalace_event_list, mempalace_kg_query) sind bisher
nur via STDIO-Binary verifiziert (ADR-008). Nach #28 in einer frischen
Freebuff-Session live ueber die Tool-Registrierung gegenpruefen.

## Acceptance Criteria

- [ ] In einer neuen Freebuff-Session listet die Tool-Registrierung mind. mempalace_search, mempalace_add_drawer und mempalace_event_list
- [ ] Test-Suche ("skill designer eval ranking") laeuft erfolgreich **ueber das MCP-Tool** (nicht CLI) und zeigt decision-Drawer
- [ ] `pwsh -File memory-ingest/check-mempalace.ps1` liefert Exit 0
- [ ] Ergebnis in Mem-Palace.md (Abschnitt MCP-Anbindungen) auf "live verifiziert" gesetzt

## Nicht-Ziel

Keine Umstellung bestehender Workflows - der CLI-Fallback bleibt als
Resilienz-Pfad bestehen (ADR-008).
