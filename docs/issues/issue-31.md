# #31: Gedaechtnis-Ergaenzung: Memory-Ingest-Decision-Drawer + KG-Fakten
<!-- mirror-sync: source=github:MaxHambi/freebuff-dev-setup#31 sha256:51f97bb76eff7297fb9757ecab8415c42468a9a3670e2cf09679e7fde02bf39b synced=2026-09-29T14:09:07Z -->

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#31](https://github.com/MaxHambi/freebuff-dev-setup/issues/31).
> Label: `ready-for-agent`. Status offen (Schliessung nach Merge).

> **Handoff 2026-09-27:** Fibel-Review bestanden, AFK-faehig. Handoff-Kommentar:
> [#31 (Kommentar)](https://github.com/MaxHambi/freebuff-dev-setup/issues/31#issuecomment-5859219112)

## Parent

Verallgemeinerung des Drawer-Sets vom 26.09.2026. Regeln:
`docs/mempalace-regeln.md`.

## Was zu tun ist (Stand 2026-09-29: erledigt)

1. ✅ **Decision-Drawer** zur Memory-Ingest-Entscheidung gefiled
   (mempalace_add_drawer via STDIO-Binary, Identity
   `maxhambi:freebuff:freebuff-dev-setup`): Wing freebuff_dev_setup,
   Room **decision**, Drawer-ID
   `drawer_freebuff_dev_setup_decision_24adf5afbaf007f4871df673`.
   Inhalt: Scheduled Task MemoryIngest (04:30 + 4 h), Staleness-Fenster
   30 min, State neben Export-Ordner, Legacy-Pfad-Idempotenz, Diagnose
   0/1/2, Transport-Update nach ADR-010.
2. ✅ **KG-Fakten** per mempalace_kg_add (Schema: subject/predicate/object):
   - `freebuff-dev-setup` → repo → `GitHub MaxHambi/freebuff-dev-setup (privat)`
   - `freebuff-dev-setup` → agent-identity → `maxhambi:freebuff:freebuff-dev-setup`
   - `freebuff-dev-setup` → session-ingest → `Scheduled Task MemoryIngest (taeglich 04:30 + 4 h), ADR-007`
   - `Freebuff` → mcp-config-path → `~/.agents/mcp.json (…ADR-010)`
   - `Freebuff` → mcp-attestation-ledger → `~/.freebuff/mcp.json (…ADR-010)`
   Alle per `mempalace_kg_query` (entity) verifiziert.
3. ✅ Verifiziert per `mempalace search "MemoryIngest Staleness-Fenster
   idempotent"`: neuer Drawer auf **Rank 1, verbatim** (Quelle
   ADR-007-Mirror).
4. ✅ Kein Duplikat: Vorab-Suche zeigte nur den Mirror-Treffer; MemPalace
   dedupliziert zudem inhaltlich (einzelner Drawer, `already_exists`-
   Antworten beim Retest bestätigen Idempotenz).

## Acceptance Criteria

- [x] Search „MemoryIngest Staleness-Fenster idempotent" liefert den neuen
      Decision-Drawer auf Rank 1
- [x] mempalace_kg_query findet die KG-Fakten (repo, agent-identity,
      session-ingest + 2 ADR-010-Facts)
- [x] Kein Duplikat (Vorab-Check + Idempotenz-Retest)
