## Parent

#1

> **Superseded (ADR-006, 2026-09-25):** Nicht gebaut - folgt aus der Einstellung der TUI-Entwicklung. Issue #10 als wontfix geschlossen.

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
