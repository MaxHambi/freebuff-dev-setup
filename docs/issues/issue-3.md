#3: Slice 2: TUI-Baum read-only - Gruppen, Navigation, Beschreibungspanel
<!-- mirror-sync: source=github:MaxHambi/freebuff-dev-setup#3 sha256:8c4c9786c13589371ee946f0bac401d305397a79fe86938ae54bda57db3f95b4 synced=2026-09-30T05:24:00Z -->

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#3](https://github.com/MaxHambi/freebuff-dev-setup/issues/3).
> Label: `ready-for-agent` / `wontfix`. Status: **geschlossen (not planned, wontfix)** — TUI-Slice; Zukunft durch ADR-006 entschieden (OpenTUI-Eigenbau eingestellt, externe Tools skill-manager/SkillSpector).
> Closure-Kommentare: [#3 (Kommentar 1)](https://github.com/MaxHambi/freebuff-dev-setup/issues/3#issuecomment-5826068911)

> Detail-Spiegel mit Implementierungsnotizen: [skills-manager/docs/issues/slice-2-tui-tree.md](../../skills-manager/docs/issues/slice-2-tui-tree.md) (keine mirror-sync-Header, dokumentierte Abweichung). Raeumungs-Kandidat (C7, 2026-09-30).

## Original-Body

## Parent

#1

## What to build

Tracer Bullet für die TUI: Ein OpenTUI-Renderer (Bun, imperatives Core – keine React/Solid-Bindings) zeigt die analysierten Skills als klappbaren Gruppenbaum: Gruppenzeilen mit Zähler, darunter die Skills. Pfeiltasten bewegen die Markierung, Enter/Rechts klappt eine Gruppe auf/zu, Enter auf einem Skill zeigt dessen Beschreibung plus Metadaten (Gruppe, Risk, Hinzufügedatum, Badges) dauerhaft überhalb der Baumliste an.

Layout folgt den OpenTUI-Terminal-Defaults: kompakt, information-dicht, keine unnötigen Paddings. Footer mit Tastenlegende. Datenquelle ist der Index aus Slice 1 (read-only). Beenden mit `q` ruft sauber `renderer.destroy()`.

Die Selektions-/Navigationslogik (Baum-Flattening, Auf/Zu, Cursor, Beschreibungspanel) ist als pure Reducer-Funktion gebaut und separat getestet; die TUI ist die dünne Anzeigeschale darüber.

## Acceptance criteria

- [ ] TUI startet mit `bun skills-manager/src/tui.ts` und zeigt Gruppen mit Skill-Zählern
- [ ] Enter/Rechts klappt eine Gruppe auf und zu; der Cursor bleibt dabei konsistent
- [ ] Enter auf einem Skill zeigt Beschreibung + Metadaten überhalb der Liste; sie bleiben stehen, bis ein anderer Eintrag markiert wird
- [ ] Pfeiltasten navigieren über Gruppen- und Skill-Zeilen hinweg ohne Hänger
- [ ] `q` beendet sauber (Terminal-Zustand wiederhergestellt)
- [ ] Renderer-Tests über das OpenTUI-Test-Utility: Baum gerendert, Gruppe aufgeklappt, Beschreibungspanel gefüllt – geprüft über Captured Frames
- [ ] Reducer-Tests (bun:test) für Flattening/Auf-Zu/Cursor-Bewegung

## Blocked by

- #2

## Kommentare

> **MaxHambi**: **Geschlossen als `wontfix` – siehe [ADR-006](https://github.com/MaxHambi/tools-entwicklung/blob/master/docs/decisions/ADR-006-externe-skill-manager-tools.md) (2026-09-25).**

Die TUI-Entwicklung des Skills-Managers ist eingestellt: Die Funktionalität dieses Slices wird abgedeckt durch

- **[skill-manager](https://github.com/abubakarsiddik31/skill-manager)** (Desktop-App, MIT) – einheitliche Sicht über elf Skills-Ordner inkl. `~/.agents/skills`, Browse/Install aus GitHub-Collections, Enable/Disable, Edit/Delete, Suche,
- **[SkillSpector](https://github.com/NVIDIA/SkillSpector)** (Scanner, Apache-2.0) – Security-Scan mit 71 Patterns und Risk-Score, statisch ohne LLM/API-Keys.

Verbleibender Scope des Skills-Managers: Analyse-CLI (Slice 1, PR #12) und optional die Mirror-Gruppierung (#6, Backlog). Die SkillSpector-Integration in die Analyse-CLI ist als eigenes ai-improvement-Issue angelegt.
