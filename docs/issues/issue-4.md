#4: Slice 3: Multi-Select, Filter & Badges in der TUI
<!-- mirror-sync: source=github:MaxHambi/freebuff-dev-setup#4 sha256:184a897dc79c48af58e078f2a146e318d1845eea6b0e54e1fa7780acb544d518 synced=2026-09-30T05:24:06Z -->

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#4](https://github.com/MaxHambi/freebuff-dev-setup/issues/4).
> Label: `ready-for-agent` / `wontfix`. Status: **geschlossen (not planned, wontfix)** — TUI-Slice; Zukunft durch ADR-006 entschieden (OpenTUI-Eigenbau eingestellt, externe Tools skill-manager/SkillSpector).
> Closure-Kommentare: [#4 (Kommentar 1)](https://github.com/MaxHambi/freebuff-dev-setup/issues/4#issuecomment-5826069704)

> Detail-Spiegel mit Implementierungsnotizen: [skills-manager/docs/issues/slice-3-select-filter-badges.md](../../skills-manager/docs/issues/slice-3-select-filter-badges.md) (keine mirror-sync-Header, dokumentierte Abweichung). Raeumungs-Kandidat (C7, 2026-09-30).

## Original-Body

## Parent

#1

## What to build

Die TUI wird interaktiv: Badges in der Baumliste, Filter, Multi-Select.

- **Badges** (aus dem Index von Slice 1, farbig): `STALE` gelb, `INCOMPAT` rot, `SETUP` blau, Risk `critical`/`offensive` rot, Risk `safe` unaufdringlich. Badges erscheinen inline hinter dem Skill-Namen.
- **Leertaste**: wählt den markierten Skill an/ab (Checkbox `[x]`/`[ ]`), über Gruppen hinweg; Auswahl überlebt Auf-/Zuklappen.
- **`a`**: wählt alle Skills der markierten Gruppe an bzw. ab (Toggle für die Gesamtgruppe).
- **`f`**: zyklischer Filter alle → nur stale → nur inkompatibel → nur needs-setup → alle; die Statuszeile zeigt den aktiven Filter.
- Kopfzeile mit Live-Statistiken (Gesamt, stale, incompat, setup, aktuell ausgewählt).

Die Selektions-/Filterlogik erweitert den Reducer aus Slice 2 (weiterhin pure, separat getestet).

## Acceptance criteria

- [ ] Leertaste toggelt die Auswahl des markierten Skills; Checkbox sichtbar; Auswahl bleibt beim Auf-/Zuklappen und Filterwechsel erhalten
- [ ] `a` toggelt die komplette markierte Gruppe
- [ ] `f` wechselt zyklisch durch vier Filter; nach jedem Wechsel enthält die Liste nur passende Skills; Statistiken in der Kopfzeile stimmen
- [ ] Badges erscheinen in den korrekten Farben laut Klassifizierung aus Slice 1
- [ ] Renderer-Tests: Badge-Zeile gefärbt gerendert, ausgewählte Zeile mit `[x]`, gefilterte Ansicht ohne inaktive Einträge
- [ ] Reducer-Tests für Toggle-Skill, Toggle-Gruppe und Filterwechsel

## Blocked by

- #3

## Kommentare

> **MaxHambi**: **Geschlossen als `wontfix` – siehe [ADR-006](https://github.com/MaxHambi/tools-entwicklung/blob/master/docs/decisions/ADR-006-externe-skill-manager-tools.md) (2026-09-25).**

Die TUI-Entwicklung des Skills-Managers ist eingestellt: Die Funktionalität dieses Slices wird abgedeckt durch

- **[skill-manager](https://github.com/abubakarsiddik31/skill-manager)** (Desktop-App, MIT) – einheitliche Sicht über elf Skills-Ordner inkl. `~/.agents/skills`, Browse/Install aus GitHub-Collections, Enable/Disable, Edit/Delete, Suche,
- **[SkillSpector](https://github.com/NVIDIA/SkillSpector)** (Scanner, Apache-2.0) – Security-Scan mit 71 Patterns und Risk-Score, statisch ohne LLM/API-Keys.

Verbleibender Scope des Skills-Managers: Analyse-CLI (Slice 1, PR #12) und optional die Mirror-Gruppierung (#6, Backlog). Die SkillSpector-Integration in die Analyse-CLI ist als eigenes ai-improvement-Issue angelegt.
