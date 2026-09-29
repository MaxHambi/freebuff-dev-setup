# #26: MemPalace: Wing tools_entwicklung zu freebuff_dev_setup umbenennen + neu minen
<!-- mirror-sync: source=github:MaxHambi/freebuff-dev-setup#26 sha256:gone synced=2026-09-29T17:42:28Z -->

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#26](https://github.com/MaxHambi/freebuff-dev-setup/issues/26).
> Label: `ready-for-agent`. Status: **geschlossen (completed)** via PR #27, gemerged als `8f520f9`.
> Closure-Kommentar: [#26 (Kommentar)](https://github.com/MaxHambi/freebuff-dev-setup/issues/26#issuecomment-5859362548)

## Original-Body

## Parent

- #21 (Ordner-Rename — der neue Default-Wing-Name folgt dem Verzeichnis)

## What to build

Der MemPalace-Wing `tools_entwicklung` (681 Drawers) wird auf `freebuff_dev_setup` umbenannt. MemPalace hat (Stand 3.10.0) **keinen nativen Wing-Rename-Befehl** — der Weg ist: YAML anpassen, neu minen, alten Wing bereinigen.

**Schritte:**
1. `mempalace.yaml` (Repo-Root): `wing: tools_entwicklung` → `wing: freebuff_dev_setup`
2. Neu minen: `mempalace mine "D:/freebuff-dev-setup"` (nach #21 heißt der Default-Wing automatisch `freebuff_dev_setup`; Alternativ `--wing freebuff_dev_setup`). Mining ist idempotent gegen die NEUE Wing-Struktur — vorab klären, ob der Miner über `source_file`-Pfade dedupliziert (dann wandern Dateien) oder Drawers dupliziert (dann Schritt 3 zwingend).
3. Alten Wing bereinigen: Möglichkeiten prüfen — `mempalace sync` (prymt nur gelöschte/gezogene Quellen, hier nicht ausreichend), `mempalace repair`, direkte Chroma-SQLite-Bereinigung. Wenn kein unterstützter Weg existiert: alten Wing als Archiv belassen und in `Mem-Palace.md` dokumentieren (Issue dann mit Anmerkung schließen, kein Datenverlust).
4. Externe Doku: `D:\mempalace\LLM-VERFEINERUNG.md` — Header-Corpus-Referenz und Init-Beispiel-Pfade `D:/tools-entwicklung` → `D:/freebuff-dev-setup`.
5. `Mem-Palace.md` Wing-Tabelle und Identity-Beispiele abgleichen (Claude-Identity-Strings wegen .claude-Ausschluss NICHT ändern).

## Acceptance criteria

- [ ] `mempalace status` zeigt Wing `freebuff_dev_setup` mit ≈681 Drawers (gleiche Room-Verteilung: skills ~529, documentation ~72, blueprint ~55, …)
- [ ] Alter Wing `tools_entwicklung`: entweder entfernt oder als dokumentiertes Archiv vermerkt
- [ ] `mempalace search "skill-designer eval"` findet Treffer im neuen Wing
- [ ] `mempalace.yaml` und `D:\mempalace\LLM-VERFEINERUNG.md` referenzieren nur noch den neuen Namen
- [ ] `Mem-Palace.md` Doku stimmt mit dem Ist-Zustand überein

## Blocked by

- #21

## Closure

Umgesetzt in PR #27, gemerged als `8f520f9`. Der Palast traegt nur noch den Wing `freebuff_dev_setup` (kein Doppel-Wing aus dem verworfenen Rename-Weg, alte Daten als Backup gesichert); Stand nach Legacy-Session-Mining und Memory-Ingest-Integration: 1089 Drawers. Der Rules-Block fuer die Identity `maxhambi:freebuff:freebuff-dev-setup` ist in AGENTS.md installiert, `.mcp.json` bereitet die MCP-Anbindung fuer #28 vor. Keine Reste.
