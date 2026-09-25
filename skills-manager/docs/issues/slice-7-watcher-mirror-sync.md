## Parent

#1

> **Superseded (ADR-006, 2026-09-25):** Nicht gebaut - kein Live-Betrieb mehr noetig; die Bibliothek wird manuell gesichtet, Delta-Laeufe laufen auf Abruf. Issue #8 als wontfix geschlossen.

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
