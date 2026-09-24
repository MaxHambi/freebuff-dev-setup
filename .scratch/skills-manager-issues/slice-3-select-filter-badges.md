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
