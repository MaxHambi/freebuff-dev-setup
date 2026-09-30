#5: Slice 4: Install-Flow - Pfad-Dialog, Copy-Engine, Summary
<!-- mirror-sync: source=github:MaxHambi/freebuff-dev-setup#5 sha256:e36f4fe4ce90beb589434c7106ad73ccd7f3ba96d7d48fa03199af420681aa61 synced=2026-09-30T05:24:09Z -->

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#5](https://github.com/MaxHambi/freebuff-dev-setup/issues/5).
> Label: `ready-for-agent` / `wontfix`. Status: **geschlossen (not planned, wontfix)** — TUI-Slice; Zukunft durch ADR-006 entschieden (OpenTUI-Eigenbau eingestellt, externe Tools skill-manager/SkillSpector).
> Closure-Kommentare: [#5 (Kommentar 1)](https://github.com/MaxHambi/freebuff-dev-setup/issues/5#issuecomment-5826070408)

> Detail-Spiegel mit Implementierungsnotizen: [skills-manager/docs/issues/slice-4-install-flow.md](../../skills-manager/docs/issues/slice-4-install-flow.md) (keine mirror-sync-Header, dokumentierte Abweichung). Raeumungs-Kandidat (C7, 2026-09-30).

## Original-Body

## Parent

#1

## What to build

Schließt den Kreis bis zur echten Projekt-Nutzung: `i` in der TUI öffnet einen Pfad-Dialog (OpenTUI Input, Default: aktuelles Arbeitsverzeichnis). Nach Eingabe erscheint eine Bestätigung mit Anzahl der ausgewählten Skills und dem Zielpfad. Nach Bestätigung wird die reine Copy-Engine ausgeführt: der komplette Skill-Ordner jedes ausgewählten Skills wird **kopiert** (nicht verschoben) in `<ziel>/<skill-name>/`. Die Bibliothek bleibt unangetastet.

Die Copy-Engine ist eine pure Lib-Funktion mit injiziertem Quell- und Ziel-Root, unabhängig von der TUI testbar: verhandelt Ziel-Konflikte (existierender Ordner → überschreiben, Zählung als "überschrieben"), überspringt auf Wunsch, sammelt Ergebnisse statt bei einem Fehler abzubrechen, und liefert eine Summary (kopiert / überschrieben / fehlgeschlagen mit Grund). Danach Zusammenfassung in der TUI, Esc/`n` bricht den Dialog ohne Aktion ab.

## Acceptance criteria

- [ ] `i` mit leerer Auswahl zeigt Hinweis, ohne Dialog
- [ ] Pfad-Dialog mit Default-Wert, Bestätigung zeigt Anzahl + Zielpfad, Abbruch tut nichts
- [ ] Copy-Engine kopiert komplette Skill-Ordner in das Ziel; Quelle bleibt unverändert
- [ ] Existierender Zielordner wird gemäß Konflikt-Entscheidung behandelt und in der Summary ausgewiesen
- [ ] Fehler bei einem Skill (z. B. Quellordner fehlt) brechen den Lauf nicht ab; Summary listet sie mit Grund
- [ ] Lib-Tests gegen tmp-Fixtures: Kopieren, Überschreiben, Konflikt, Teilerfolg nach Fehler
- [ ] Renderer-Test für den Bestätigungsdialog und die Summary-Anzeige

## Blocked by

- #4

## Kommentare

> **MaxHambi**: **Geschlossen als `wontfix` – siehe [ADR-006](https://github.com/MaxHambi/tools-entwicklung/blob/master/docs/decisions/ADR-006-externe-skill-manager-tools.md) (2026-09-25).**

Die TUI-Entwicklung des Skills-Managers ist eingestellt: Die Funktionalität dieses Slices wird abgedeckt durch

- **[skill-manager](https://github.com/abubakarsiddik31/skill-manager)** (Desktop-App, MIT) – einheitliche Sicht über elf Skills-Ordner inkl. `~/.agents/skills`, Browse/Install aus GitHub-Collections, Enable/Disable, Edit/Delete, Suche,
- **[SkillSpector](https://github.com/NVIDIA/SkillSpector)** (Scanner, Apache-2.0) – Security-Scan mit 71 Patterns und Risk-Score, statisch ohne LLM/API-Keys.

Verbleibender Scope des Skills-Managers: Analyse-CLI (Slice 1, PR #12) und optional die Mirror-Gruppierung (#6, Backlog). Die SkillSpector-Integration in die Analyse-CLI ist als eigenes ai-improvement-Issue angelegt.
