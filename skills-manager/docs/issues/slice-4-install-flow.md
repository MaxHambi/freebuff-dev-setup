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
