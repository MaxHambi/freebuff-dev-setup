## Parent

#1

> **Superseded (ADR-006, 2026-09-25):** Nicht gebaut - Suche via [skill-manager](https://github.com/abubakarsiddik31/skill-manager); routed bleibt ueber MCP (`route_skill`) erreichbar. Issue #9 als wontfix geschlossen.

## What to build

Semantische Suche in der TUI: `/` öffnet eine Suchleiste (OpenTUI Input), die Eingabe wird an `routed route "<query>" --json` geschickt (über die installierte routed-CLI via PowerShell, Fehler werden abgefangen). Die zurückgegebenen Skill-Treffer werden im Baum hervorgehoben (z. B. Relevanz-Rang als Zahl), Nicht-Treffer ausgegraut; die Ansicht ist ein Overlay-Modus, der mit Esc verlassen wird und den normalen Baum unbeschädigt zurücklässt. Suche funktioniert gruppenübergreifend über alle Skills des Index.

Die Auswertung der routed-JSON-Antwort (Pfadematching gegen den Index, Ranking-Übernahme) ist als pure Funktion getestet; die TUI zeigt nur das Ergebnis. Ohne erreichbares routed bleibt die Suche lokal (Substring-Match über Name/Beschreibung), damit das Feature nicht komplett wegbricht.

## Acceptance criteria

- [ ] `/` öffnet Suchleiste, Eingabe löst routed-Anfrage aus, Treffer sind im Baum hervorgehoben mit Rang
- [ ] Esc verlässt den Suchmodus; Baum, Auswahl und Cursor sind im Originalzustand
- [ ] Die Auswertefunktion mappt routed-Treffer korrekt auf Index-Einträge (inkl. Pfad-Varianten) und übernimmt das Ranking
- [ ] Ohne erreichbare routed-CLI greift lokaler Substring-Fallback, es gibt keinen Absturz
- [ ] Lib-Tests für die JSON-Auswertung und den Fallback; Renderer-Test für Hervorhebung + Overlay

## Blocked by

- #3
