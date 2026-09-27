# #28: Freebuff-Consent fuer mempalace-MCP-Server freischalten

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#28](https://github.com/MaxHambi/freebuff-dev-setup/issues/28).
> Label: `ready-for-human`. Status offen.

## Ausgangslage (verifizierte Fakten)

- `.mcp.json` (Repo, seit 26.09.2026 bewusst lokal/gitignored, siehe ADR-009) registriert `mempalace-mcp.exe` fuer Freebuff.
- Consent-State `~/.freebuff/mcp.json` enthaelt **keinen** mempalace-Eintrag (nur supabase/rayrun/synapse/routed/claimidx).
- Binary gesund: Smoke-Test `initialize` + `tools/list` = mempalace 3.10.0 mit **45 Tools** via STDIO.
- Palast-Suche OK (CLI-Fallback aktiv, 5 Treffer auf Test-Query). Diagnose: `pwsh -File memory-ingest/check-mempalace.ps1` liefert aktuell **Exit 2** (GELB).

## Warum menschliche Umsetzung

Der Consent-Prompt fuer projekt-lokale MCP-Server existiert nur in der
Freebuff-UI; es gibt keinen CLI-/Config-Weg (Approval-State liegt app-intern,
Hash-Keys in `~/.freebuff/mcp.json`).

## Checkliste

- [ ] Freebuff-UI: Consent fuer den Server aus `.mcp.json` (mempalace) bestaetigen
- [ ] `pwsh -File memory-ingest/check-mempalace.ps1` liefert **Exit 0** (Gesamt: GRUEN)
- [ ] Optional gegenpruefen: `~/.freebuff/mcp.json` enthaelt mempalace-Eintrag mit `enabled: true` und 45 `allowedTools`
