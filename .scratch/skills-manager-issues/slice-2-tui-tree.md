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
