# #56: Slice 3 — Diagnose-Hinweis auf ADR-010-Weg + #29 Re-Scope (STDIO-Verifikation)
<!-- mirror-sync: source=github:MaxHambi/freebuff-dev-setup#56 sha256:gone synced=2026-09-29T17:42:36Z -->

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#56](https://github.com/MaxHambi/freebuff-dev-setup/issues/56).
> Label: `ready-for-agent`. Status offen.

## Ziel

Slice 3 aus [docs/plan-2026-09-29-ready-for-human.md](../plan-2026-09-29-ready-for-human.md):
Den veralteten Consent-Hinweis der Diagnose korrigieren und #29 auf den
realen Weg re-scopen.

## Umfang

- [x] [check-mempalace.ps1](../../memory-ingest/check-mempalace.ps1): WARN-Text ersetzt durch „Server in der Freebuff-UI hinzufuegen (schreibt ~/.agents/mcp.json, ADR-010), nach Neustart freigeben"; Header-Verweis auf ADR-010 ergaenzt
- [x] #29 re-scoped: STDIO-Live-Test der drei Schluessel-Tools erledigt (search/event_list/kg_query alle OK, kg-Parameter heisst `entity`); native-Tool-Check im frischen Thread nach Restart als Rest dokumentiert (Mirror [issue-29.md](issue-29.md) + Kommentar)
- [x] Mirror + Commit + PR in den Entwicklungsbranch

## Akzeptanz

- ✅ Diagnose-Text nennt den ADR-010-Weg
- ✅ `npm run verify` gruen (Pre-Push-Gate)
- ✅ PR gemergt in `feat/ready-for-human-closeout`
