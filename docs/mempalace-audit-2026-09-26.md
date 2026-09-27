# MemPalace-Integrations-Audit (2026-09-26)

Read-only-Audit der MemPalace-Anbindung dieses Projekts, ausgeführt in der
Session vom 26.09.2026. Reparaturen sind im Abschnitt "Repariert" markiert;
dauerhafte Regeln stehen in `docs/mempalace-regeln.md`.

## Palace-Gesundheit

| Kennzahl | Wert (vor Audit) | Wert (nach Re-Mine) |
|---|---|---|
| Drawers gesamt | 899 | **1003** |
| Wing | `freebuff_dev_setup` | unverändert |
| Room decision | 24 | 24 |
| Room documentation | 72 | 111 (ADRs, docs/* heute) |
| Room skills | 538 | 533 (sync-Effekte durch Re-Mine) |
| Room task / testing / general | 14 / – / 6 | 39 / 23 / 20 |
| Hallways | 7007 | unverändert gemessen |

Wachstum ist plausibel: Der Repo-Re-Mine hat die seit dem Palast-Rebuild
(25.09.) neuen/geänderten Dateien gefilmt (ADRs 007–009, memory-ingest/*,
Session-Log, Issue-Mirror).

## Befunde

1. **L0-Identity fehlte** — `mempalace wake-up` meldete "No identity
   configured; create ~/.mempalace/identity.txt". Die Identity
   (`maxhambi:freebuff:freebuff-dev-setup`) stand nur in den Instructions,
   nicht in der L0-Datei. **Repariert:** Datei angelegt, wake-up zeigt sie
   als Kopfzeile.
2. **Logstream-CLI-Schema-Abweichung** — das MCP-Schema von
   `mempalace_event_list` kennt `preview: true`; die CLI
   (`mempalace logstream list`) kennt dieses Flag **nicht** (Usage-Fehler).
   Agenten müssen auf der CLI `--limit` statt `--preview` verwenden.
   **Getestet:** `mempalace logstream list --to-agent
   maxhambi:freebuff:freebuff-dev-setup --limit 10` → "No matching events."
   (Leerscan, declared-idle bestätigt, kein Cursor nötig.)
3. **Repo-Mining-Rückstand** — zwischen Palast-Rebuild (25.09.) und diesem
   Audit war kein `mempalace mine` über das Repo gelaufen; alle Änderungen
   dieser Session waren nur über Convos-Mining bzw. manuelle Drawers im
   Palast. **Repariert:** idempotenter Re-Mine (s. u.), künftig Teil der
   Regeln (Abgleich bei größerer Doku-Arbeit).
4. **`memory_ingest`-Room fehlt** — die memory-ingest-Dateien landen im
   Re-Mine nach `general`/`testing`, weil `mempalace.yaml` das Mapping
   nicht kennt (Edit-Tool-Blockade). **Offen:** Issue #30
   (`ready-for-human`), danach erneuter Sync.
5. **`update check`: `restart_required_after_upgrade: true`** —
   bewertet als **unkritisch**: Der MCP-Server startet pro Call frisch
   (STDIO), die CLI ist auf jedem Aufruf aktuell; ein Neustart ist nur
   relevant, wenn ein langlebiger Daemon/`serve` laufen würde (tut er nicht).
6. **MCP-Consent weiterhin offen** — `check-mempalace.ps1` liefert Exit 2
   (nur Consent fehlt, Binary + Suche grün). Issue #28; Fallback-Pfad
   sanktioniert per ADR-008.

## Such-Qualität (Stichprobe)

| Query-Muster | Ergebnis |
|---|---|
| Exakte Begriffe ("skill designer eval ranking") | Top-Treffer aus decision-Room, wie gewohnt stark |
| Decision-Konzept ("Umbenennung Claude-Code-Harness Issue #24") | Rank 1 = gefilterter Decision-Drawer |
| Neue ADR ("Staleness-Fenster statt Skip-Liste Daemon verworfen") | Rank 1 = ADR-007 nach Re-Mine |

Fazit: Exakte Begriffe schlagen Prosa-Fragen (bekanntes Muster); nach dem
Re-Mine sind auch frische ADRs sofort auffindbar.

## Durchgeführte Operationen

- `~/.mempalace/identity.txt` angelegt (L0)
- `mempalace mine D:/freebuff-dev-setup` (idempotent: 899 → 1003 Drawers)
- Inbox-Sweep korrigiert und dokumentiert (Leerscan)
- Keine Schreiboperationen auf Logstream/Tunnels (immutable, keine Smoke-Events)
