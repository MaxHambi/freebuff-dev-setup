#10: Slice 9: TUI-Live-Integration - Watcher-Thread, Rescan, Feinschliff
<!-- mirror-sync: source=github:MaxHambi/freebuff-dev-setup#10 sha256:8e25728b0c29f4f093ca00929dbf6fc97a1fbadd54119cf5d2c9efaf33a9750a synced=2026-09-30T05:23:53Z -->

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#10](https://github.com/MaxHambi/freebuff-dev-setup/issues/10).
> Label: `ready-for-agent` / `wontfix`. Status: **geschlossen (not planned, wontfix)** — TUI-Slice; Zukunft durch ADR-006 entschieden (OpenTUI-Eigenbau eingestellt, externe Tools skill-manager/SkillSpector).
> Closure-Kommentare: [#10 (Kommentar 1)](https://github.com/MaxHambi/freebuff-dev-setup/issues/10#issuecomment-5826072169)

> Detail-Spiegel mit Implementierungsnotizen: [skills-manager/docs/issues/slice-9-tui-live.md](../../skills-manager/docs/issues/slice-9-tui-live.md) (keine mirror-sync-Header, dokumentierte Abweichung). Raeumungs-Kandidat (C7, 2026-09-30).

## Original-Body

## Parent

#1

## What to build

Finaler Zusammenschluss: Die TUI bekommt den Watcher (Slice 7) als Hintergrund-Thread (`--watch` ist Default, abschaltbar), einen manuellen Rescan und die Feinschliffe.

- **Live-Updates**: Während die TUI offen ist, laufen Watcher-Deltas ein; Baum, Badges und Statistiken aktualisieren sich automatisch. Der Status "syncing…" verhindert irritierende Halb-Zustände; frisch hinzugekommene Skills bekommen ein `NEW`-Badge (bis zum nächsten Fokuswechsel).
- **`F5`/`u`**: manueller Rescan (Delta-Lauf aus Slice 6) – auch sinnvoll, wenn die TUI ohne Watcher läuft.
- **`r`**: `routed reindex` manuell anstoßen; die Statuszeile zeigt Erfolg/Fehler.
- **Hilfe-Footer** vervollständigt (alle Tasten inklusive neuer), `q` beendet Watcher-Thread und Renderer sauber.

Die Integration ist bewusst schlank: Sie verbindet getestete Teile (Reducer, Delta, Sync), keine neue Fachlogik.

## Acceptance criteria

- [ ] TUI mit Watcher: neuer Skill-Ordner wird während offener TUI sichtbar (Badge `NEW`), gelöschter verschwindet, ohne Absturz oder Geister-Einträge
- [ ] `F5`/`u` stößt Delta-Rescan an; Statistiken aktualisieren sich
- [ ] `r` führt routed reindex aus; Fehler landen sichtbar in der Statuszeile, kein Absturz
- [ ] `--no-watch` startet ohne Hintergrund-Thread; Rest der TUI funktioniert
- [ ] Footer zeigt alle Tasten; `q` beendet Watcher und Renderer sauber
- [ ] Renderer-Test: syncing-Zeile und NEW-Badge; Integrationstest: Rescan-Aufruf aktualisiert die Ansicht

## Blocked by

- #4, #5, #8

## Kommentare

> **MaxHambi**: **Geschlossen als `wontfix` – siehe [ADR-006](https://github.com/MaxHambi/tools-entwicklung/blob/master/docs/decisions/ADR-006-externe-skill-manager-tools.md) (2026-09-25).**

Die TUI-Entwicklung des Skills-Managers ist eingestellt: Die Funktionalität dieses Slices wird abgedeckt durch

- **[skill-manager](https://github.com/abubakarsiddik31/skill-manager)** (Desktop-App, MIT) – einheitliche Sicht über elf Skills-Ordner inkl. `~/.agents/skills`, Browse/Install aus GitHub-Collections, Enable/Disable, Edit/Delete, Suche,
- **[SkillSpector](https://github.com/NVIDIA/SkillSpector)** (Scanner, Apache-2.0) – Security-Scan mit 71 Patterns und Risk-Score, statisch ohne LLM/API-Keys.

Verbleibender Scope des Skills-Managers: Analyse-CLI (Slice 1, PR #12) und optional die Mirror-Gruppierung (#6, Backlog). Die SkillSpector-Integration in die Analyse-CLI ist als eigenes ai-improvement-Issue angelegt.
