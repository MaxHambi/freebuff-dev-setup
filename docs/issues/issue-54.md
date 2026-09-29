# #54: Slice 1 — ADR-010 (Freebuff-MCP-Pfad), ADR-011 (MemPalace-Übersicht) + Navigations-Drawer

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#54](https://github.com/MaxHambi/freebuff-dev-setup/issues/54).
> Label: `ready-for-agent`. Status offen.

## Ziel

Die Befunde vom 29.09.2026 zur Freebuff-MCP-Anbindung dauerhaft dokumentieren
und den MemPalace-Palast selbstbeschreibend machen. Slice 1 aus
[docs/plan-2026-09-29-ready-for-human.md](../plan-2026-09-29-ready-for-human.md).

## Umfang

- [x] [ADR-010](../decisions/ADR-010-freebuff-mcp-config-pfad.md): Freebuff liest/schreibt `~/.agents/mcp.json` als Standardpfad; `~/.freebuff/mcp.json` = Attestierungs-Ledger (nie manuell editieren); Projekt-`.mcp.json` bleibt (ADR-009 unangetastet, Consent-Fluss supersedet)
- [x] [ADR-011](../decisions/ADR-011-mempalace-uebersicht-navigation.md): selbstbeschreibender Palast via Navigations-Drawer „Palast-Index" + Pflege-Regel
- [x] [docs/mempalace-uebersicht.md](../mempalace-uebersicht.md): Wing, Rooms, Drawer-Kategorien, Suchbeispiele
- [x] AGENTS.md: Referenzzeile auf die Übersicht (außerhalb des kanonischen Shared-Brain-Blocks)
- [x] `docs/index.md` + README-Tabelle ergänzt (ADR-001 bis ADR-011)
- [x] MemPalace-Drawers: ADR-010 (`drawer_freebuff_dev_setup_documentation_d970ac7684874964a15f4163`), ADR-011 (`..._fc01ba9ddf4576539cba1f9c`), „Palast-Index" (`..._fcb73a9a7821660b63fbf582`) — alle via STDIO-JSONRPC (ADR-008-Muster, Identity `maxhambi:freebuff:freebuff-dev-setup`), per `mempalace search` verifiziert
- [x] Mirror + PR in den Entwicklungsbranch

## Akzeptanz

- ✅ Beide ADRs indiziert (docs/index.md), Übersicht von AGENTS.md referenziert.
- ✅ Drawers via `mempalace search` auffindbar („Palast-Index" → ADR-011-Drawer, „ADR-010 globaler Pfad" → ADR-010-Drawer).
- ✅ `npm run verify` grün (Pre-Push-Gate), Slice-PR gemergt in `feat/ready-for-human-closeout`.
