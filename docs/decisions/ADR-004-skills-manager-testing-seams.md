# ADR-004: Skills-Manager - zwei Test-Seams (Lib-Funktionen + TUI-Renderer)

## Status

Accepted

## Date

2026-09-24

## Context

Der Skills-Manager (PRD #1) mischt Dateisystem-Logik (Scanner, Delta, Copy-Engine), pure Reducer-Logik (TUI-Zustand) und eine native TUI (OpenTUI auf Bun). Fuer die Tests mussten Seams gewaehlt werden - der PRD-Prozess verlangte eine explizite Entscheidung, die User wuenschte zusaetzlich zu den Lib-Tests die Renderer-Tests.

Randbedingungen:

- Bun ist die Pflicht-Laufzeit (OpenTUI-Mindestversion); bun:test steht bereit
- OpenTUI bringt `testRender()` mit (captured Frames, Keyboard-Events, Resize)
- Die echte Bibliothek (1.872+ Skills) ist kein Testziel - Tests laufen gegen tmp-Fixtures
- Windows-CI (ubuntu + windows Matrix) muss beide Seams ohne native Win-Abhaengigkeit ausfuehren koennen

## Decision

**Zwei Seams, bewusst begrenzt:**

1. **Lib-Seam**: Alle Kernlogik (scan, classify, delta, report, mirror, install) als pure Funktionen mit injiziertem Skills-Root. Tests erzeugen tmp-Fixtures und pruefen ausschliesslich Resultate (Index-Inhalt, Klassifizierung, Zielordner nach Sync/Install). Kein Mocken von fs-Interna.
2. **TUI-Seam**: Reducer-Logik (Selektion, Navigation, Filter) ist pure und wird wie die Lib getestet; die Rendering-Schale wird mit `testRender()` gegen Captured Frames geprueft (Baum gerendert, Badge gefaerbt, Beschreibungspanel gefuellt).

Nicht getestet werden: Timing-Verhalten von fs.watch (stattdessen Delta-Logik-Tests), echte routed-CLI-Aufrufe (stattdessen Antwort-Auswertung + Fallback-Pfad), native Renderer-Interna.

## Alternatives Considered

### Nur Lib-Tests (TUI als ungetestete duenne Schale)
- Pros: Am wenigsten Aufwand, keine native-Abhaengigkeit im CI
- Cons: Gerade Selektion/Filter/Badges sind fehleranfaellig und UI-sichtbar; der User bat explizit um Renderer-Tests
- Rejected: User-Entscheidung im PRD-Prozess

### Ende-zu-Ende durch die echte TUI mit pty-Emulation
- Pros: Naechster an der Realitaet
- Cons: Bruchanfaellig auf CI (pseudo-tty auf Windows-Runner), langsam, native Renderer-Abhaengigkeit
- Rejected: Kosten/Nutzen steht in keinem Verhaeltnis, testRender deckt Frames ab

### Snapshot-Tests der gesamten Frames
- Pros: Einfach zu schreiben
- Cons: Zerbrechen bei jeder Layout-Nuance, verbergen das Wesentliche
- Rejected: Stattdessen gezielte Frame-Assertions (enthaltene Zeilen/Farben)

## Consequences

- Neue Features brauchen in der Regel: 1 Lib-Test-Datei + 1 Reducer-Test + (bei UI-Aenderung) eine Frame-Assertion
- OpenTUI-Test-Utility wird zur festen Dev-Abhaengigkeit ab Slice 2
- CI muss bun + OpenTUI-Native auf beiden OS-Targets laden koennen - Laufzeit-Check steht in Slice 2 an
- Die 25 bestehenden Tests (Slice 1) folgen bereits diesem Muster

## Related

- PRD #1 (Testing Decisions - dort vom User bestaetigt)
- Issue #3 (Slice 2, erster Einsatz des TUI-Seams)
- PR #12 (Slice 1, Referenz-Implementierung der Lib-Tests)
