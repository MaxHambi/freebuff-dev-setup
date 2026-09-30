#8: Slice 7: Watcher & Mirror-Sync - Update-Erkennung im laufenden Betrieb
<!-- mirror-sync: source=github:MaxHambi/freebuff-dev-setup#8 sha256:53e72785b30d7976cc637e254bb56f514a7fcecf8cac849f40f3c45456ed7f4f synced=2026-09-30T05:24:15Z -->

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#8](https://github.com/MaxHambi/freebuff-dev-setup/issues/8).
> Label: `ready-for-agent` / `wontfix`. Status: **geschlossen (not planned, wontfix)** — TUI-Slice; Zukunft durch ADR-006 entschieden (OpenTUI-Eigenbau eingestellt, externe Tools skill-manager/SkillSpector).
> Closure-Kommentare: [#8 (Kommentar 1)](https://github.com/MaxHambi/freebuff-dev-setup/issues/8#issuecomment-5826071012)

> Detail-Spiegel mit Implementierungsnotizen: [skills-manager/docs/issues/slice-7-watcher-mirror-sync.md](../../skills-manager/docs/issues/slice-7-watcher-mirror-sync.md) (keine mirror-sync-Header, dokumentierte Abweichung). Raeumungs-Kandidat (C7, 2026-09-30).

## Original-Body

## Parent

#1

## What to build

Verbindet Delta-Index (Slice 6) und Mirror (Slice 5) zur Automatisierung für das laufende Aufräumen: Ein Watcher überwacht den Skills-Ordner (`fs.watch` mit Debounce von ~2 s), bündelt Ereignisse und stößt für das Delta den Mirror-Sync an: neue Skills werden analysiert, in die gecachte Gruppe einsortiert (Buckets aus Slice 5, bei Bucket-losen routed-Fallback) und in den Mirror kopiert; geänderte werden im Mirror ersetzt; gelöschte aus dem Mirror entfernt. Nach gebündelten Änderungen wird `routed reindex` angestoßen (Fehler werden abgefangen).

Der Watcher ist als eigenständiger Modus nutzbar (CLI, läuft neben der TUI) und als Hintergrund-Thread innerhalb der TUI (Slice 9). Das Debounce/Bündeln ist als pure Logik testbar (Ereignis-Strom → gebündelte Delta-Aufträge), kein Timing-Test auf echtem fs.watch.

## Acceptance criteria

- [ ] Beim Anlegen eines Skill-Ordners während laufendem Watcher: nach Debounce erscheint er im Index, State, Report und Mirror (in korrekter Gruppe)
- [ ] Beim Ändern/Löschen: Mirror-Eintrag wird ersetzt bzw. entfernt, Index bleibt konsistent
- [ ] Schnell aufeinanderfolgende Ereignisse werden gebündelt (ein Sync-Lauf, nicht zehn)
- [ ] `routed reindex` wird nach gebündelten Änderungen versucht; ohne routed läuft der Sync trotzdem durch
- [ ] Watcher-CLI beendet sich sauber (Strg+C) und hinterlässt konsistenten State
- [ ] Lib-Tests: Bündelungs-Logik (Ereignis-Strom → Delta-Aufträge), Sync-Auftrag gegen tmp-Fixture (add/change/delete)

## Blocked by

- #7
- #6

## Kommentare

> **MaxHambi**: **Geschlossen als `wontfix` – siehe [ADR-006](https://github.com/MaxHambi/tools-entwicklung/blob/master/docs/decisions/ADR-006-externe-skill-manager-tools.md) (2026-09-25).**

Die TUI-Entwicklung des Skills-Managers ist eingestellt: Die Funktionalität dieses Slices wird abgedeckt durch

- **[skill-manager](https://github.com/abubakarsiddik31/skill-manager)** (Desktop-App, MIT) – einheitliche Sicht über elf Skills-Ordner inkl. `~/.agents/skills`, Browse/Install aus GitHub-Collections, Enable/Disable, Edit/Delete, Suche,
- **[SkillSpector](https://github.com/NVIDIA/SkillSpector)** (Scanner, Apache-2.0) – Security-Scan mit 71 Patterns und Risk-Score, statisch ohne LLM/API-Keys.

Verbleibender Scope des Skills-Managers: Analyse-CLI (Slice 1, PR #12) und optional die Mirror-Gruppierung (#6, Backlog). Die SkillSpector-Integration in die Analyse-CLI ist als eigenes ai-improvement-Issue angelegt.
