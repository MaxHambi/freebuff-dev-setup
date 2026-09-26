# #31: Gedaechtnis-Ergaenzung: Memory-Ingest-Decision-Drawer + KG-Fakten

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#31](https://github.com/MaxHambi/freebuff-dev-setup/issues/31).
> Label: `needs-triage`. Status offen.

## Parent

Verallgemeinerung des Drawer-Sets vom 26.09.2026 (Backup-Loeschung,
Legacy-Session-Mining, Projekt-Umbenennung - alle per mempalace_add_drawer
gefiled und per Suche auf Rank 1 verifiziert). Regeln: `docs/mempalace-regeln.md`.

## Was zu tun ist

1. **Vierter Decision-Drawer** zur Memory-Ingest-Entscheidung file-en
   (mempalace_add_drawer via STDIO-Binary bis #28):
   - Wing freebuff_dev_setup, Room decision, added_by
     maxhambi:freebuff:freebuff-dev-setup
   - Inhalt: Scheduled Task MemoryIngest (taeglich 04:30 + 4 h), Live-Schutz
     30 min Staleness-Fenster (kein Hardcode-Skip mehr), State neben dem
     Export-Ordner (mine liest ihn sonst als _registry-Junk), Export-Ordner
     bewusst = Legacy-Pfad (mine ist pro Quellpfad idempotent), Diagnose-
     Script check-mempalace.ps1 (Exit 0/1/2)
   - Quellenpfad: ADR-007 (`docs/decisions/ADR-007-memory-ingest-scheduled-task.md`)
2. **KG-Fakten** per mempalace_kg_add anlegen (supersede-faehig statt
   Freitext-Drawer):
   - Repo heisst freebuff-dev-setup (GitHub MaxHambi/freebuff-dev-setup)
   - Freebuff-Agent-Identity ist maxhambi:freebuff:freebuff-dev-setup
   - Session-Ingest laeuft als Scheduled Task MemoryIngest
3. Verifizieren per `mempalace search` (woertliche Treffer).

## Acceptance Criteria

- [ ] Search "MemoryIngest Staleness-Fenster idempotent" liefert den neuen Decision-Drawer auf Rank 1
- [ ] mempalace_kg_query findet die drei KG-Fakten
- [ ] Kein Duplikat: Vor dem Filing per Suche gegenpruefen, ob der Drawer schon existiert
