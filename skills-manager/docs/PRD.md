# PRD: Skills-Manager – Analyse-CLI (v2, nach ADR-006)

> **Hinweis (2026-09-25, ADR-006):** Die ursprüngliche Planung sah eine
> OpenTUI-Terminal-App vor (Gruppenbaum, Multi-Select, Install-Flow,
> Suche, Watcher-Live). Diese Teile sind verworfen: Die funktionalen
> Entsprechungen werden heute durch
> [abubakarsiddik31/skill-manager](https://github.com/abubakarsiddik31/skill-manager)
> (Baum, Multi-Select, Install, Suche, Enable/Disable) und
> [NVIDIA/SkillSpector](https://github.com/NVIDIA/SkillSpector)
> (Security-Scan, Risk-Score) abgedeckt. Die User Stories 1–15 und
> 20–33 der ursprünglichen Fassung sind damit gegenstandslos. Verbleibender
> Scope sind die Analyse-CLI (unten) und – als Backlog – die Mirror-
> Gruppierung (Stories 16–19).

Slices und Implementierungsstand: siehe `PROCESS.md` (Issue-Map) und
`docs/issues/` (Slice-Dokumente mit Superseded-Vermerken nach ADR-006).

## Problem Statement

In der persönlichen Skill-Bibliothek unter dem globalen Skills-Ordner liegen über 1.800 Skills, die organisch gewachsen sind und laufend ergänzt sowie aufgeräumt werden. Aus Sicht der Nutzerin/des Nutzers ist der Bestand ein undurchsichtiger flacher Ordner-Berg:

- Es ist nicht erkennbar, welche Skills veraltet, kaputt oder ohne zusätzliches Setup unbrauchbar sind.
- Thematisch zusammengehörige Skills liegen nicht beieinander; es gibt keine durchsuchbare, gruppierte Sicht.
- Skills in ein konkretes Projekt zu übernehmen erfordert manuelles Kopieren von Ordnern.
- Da der Ordner aktiv aufgeräumt wird, veralten jede Analyse, jeder Index und jeder Mirror sofort wieder.

## Solution

Ein Skills-Manager als **Analyse-CLI** (Bun), der die Bibliothek scannt, jeden Skill klassifiziert (`stale` / `incompat` / `needs-setup`) und einen maschinenlesbaren Index plus lesbaren Report erzeugt. Ein Delta-Index mit Hash-basierter Move-Erkennung hält Folgelauf beim laufenden Aufräumen aktuell. Die interaktiven Teile (Baum, Multi-Select, Install, Suche) sind nach ADR-006 extern abgedeckt (skill-manager, SkillSpector); die optionale Anreicherung mit SkillSpector-Risk-Scans ist als ai-improvement-Issue angelegt.

## User Stories

1. Als Skill-Nutzer will ich beim Öffnen der TUI sofort alle Gruppen auf- und zuklappen können, damit ich mich thematisch orientieren kann.
2. Als Skill-Nutzer will ich mit der Leertaste beliebig viele Skills über Gruppen hinweg an- und abwählen können, damit ich mehrere Skills in einem Durchgang installieren kann.
3. Als Skill-Nutzer will ich mit `a` eine ganze Gruppe an- oder abwählen können, damit ich nicht jeden Skill einzeln anklicken muss.
4. Als Skill-Nutzer will ich, dass bei Enter die Beschreibung des markierten Skills überhalb der TUI erscheint, damit ich vor der Auswahl weiß, was der Skill tut.
5. Als Skill-Nutzer will ich in der Beschreibungszeile auch Metadaten (Gruppe, Risk, Hinzufügedatum, Badges) sehen, damit ich die Qualität auf einen Blick einschätzen kann.
6. Als Skill-Nutzer will ich Badges für veraltete Skills sehen, damit ich weiß, welche Inhalte womöglich überholt sind.
7. Als Skill-Nutzer will ich Badges für inkompatible Skills sehen, damit ich Skills mit kaputten Skript-Referenzen oder Binär-Müll meiden kann.
8. Als Skill-Nutzer will ich Badges für Skills sehen, die weiteres Setup benötigen (API-Keys, MCP-Server, Python-Pakete), damit ich nicht auf halbem Weg steckenbleibe.
9. Als Skill-Nutzer will ich nach Risk-Level filtern können, damit ich riskante Skills nicht versehentlich installiere.
10. Als Skill-Nutzer will ich mit `f` zwischen Filtern (alle / nur stale / nur inkompatibel / nur Setup nötig) umschalten können, damit ich gezielt aufräumen kann.
11. Als Skill-Nutzer will ich mit `/` semantisch über alle Skills suchen können, damit ich auch bei unbekannten Begriffen fündig werde.
12. Als Skill-Nutzer will ich mit `i` einen Zielpfad-Dialog bekommen, in den ich den Projektordner eingebe, damit die Installation genau dorthin geschieht.
13. Als Skill-Nutzer will ich vor der Installation eine Bestätigung mit Anzahl und Zielpfad sehen, damit ich nichts versehentlich überschreibe.
14. Als Skill-Nutzer will ich, dass installierte Skills als Kopie landen und in meiner Bibliothek erhalten bleiben, damit ich sie in mehreren Projekten nutzen kann.
15. Als Skill-Nutzer will ich nach der Installation eine Zusammenfassung (erfolgreich / übersprungen / Konflikte) sehen, damit ich den Erfolg prüfen kann.
16. Als Skill-Nutzer will ich einen Gruppen-Mirror in einem separaten Ordner, damit meine originale Bibliothek unangetastet bleibt.
17. Als Skill-Nutzer will ich, dass der Mirror thematische Gruppenordner enthält, damit ich die Bibliothek auch im Datei-Explorer thematisch navigieren kann.
18. Als Skill-Nutzer will ich, dass Container-Ordner (Docs, LibreOffice, Security-Suiten, unvollständige Ordner) als eigene Gruppen erhalten bleiben, damit keine Inhalte verloren gehen.
19. Als Skill-Nutzer will ich, dass der Mirror als Dry-Run-Report existiert, bevor irgendetwas kopiert wird, damit ich die Gruppierung vorher prüfen kann.
20. Als Skill-Nutzer will ich, dass Änderungen am Skills-Ordner (neue, geänderte, gelöschte, umbenannte Skills) automatisch registriert werden, damit der Bestand immer aktuell ist, während ich aufräume.
21. Als Skill-Nutzer will ich, dass der Index nur Deltas neu analysiert statt alles neu zu scannen, damit Rescans bei 1.800+ Skills schnell bleiben.
22. Als Skill-Nutzer will ich, dass Umbenennungen über den Inhalt erkannt werden, damit keine Doppel-Einträge entstehen.
23. Als Skill-Nutzer will ich, dass der Mirror inkrementell nachgezogen wird, damit ich ihn jederzeit als aktuelle thematische Kopie nutzen kann.
24. Als Skill-Nutzer will ich, dass der Routed-Index nach Änderungen neu aufgebaut wird, damit semantische Suche die neuen Skills findet.
25. Als Skill-Nutzer will ich frisch hinzugekommene Skills als solches markiert sehen, damit ich sie direkt sichte.
26. Als Skill-Nutzer will ich mit einer Taste manuell einen Rescan anstoßen können, damit ich nicht auf den Watcher warten muss.
27. Als Skill-Nutzer will ich eine Statuszeile, die mir anzeigt, dass gerade synchronisiert wird, damit ich weiß, dass die Ansicht kurz veraltet sein kann.
28. Als Skill-Nutzer will ich, dass die TUI auch ohne laufenden Routed-Dienst funktioniert, damit ein Ausfall von Routed mich nicht blockiert.
29. Als Skill-Nutzer will ich eine kompakte, information-dichte TUI ohne Web-Layout-Overhead, damit auf normalen Terminalgrößen alles sichtbar bleibt.
30. Als Skill-Nutzer will ich eine Hilfe-Legende im Footer, damit ich alle Tasten ohne Dokumentation finde.
31. Als Skill-Nutzer will ich mit `q` sauber beenden können, damit mein Terminal nicht in einem kaputten Zustand zurückbleibt.
32. Als Skill-Nutzer will ich einen REPORT.md-Report der Analyse (Zahlen pro Gruppe und Status), damit ich den Gesundheitszustand der Bibliothek auch außerhalb der TUI lesen kann.
33. Als Skill-Nutzer will ich, dass alle Daten-Dateien (Index, State, Manifest) maschinenlesbar versioniert sind, damit andere Tools darauf aufbauen können.

## Implementation Decisions

- **Runtimes:** Bun (≥1.3.0, lokal 1.3.6) als Laufzeit; Node.js-Pfad wird nicht unterstützt.
- **Module:** Analyse/Klassifizierung (pure Funktionen), Gruppierung (Buckets + routed-Fallback), Mirror-Sync (kopieren/entfernen/ersetzen), Delta-Index (Hash-und-Mtime-State), Install (Copy mit Bestätigung), TUI (Baum, Badges, Dialoge), Watcher (fs.watch mit Debounce).
- **Klassifizierung:** stale = `date_added` älter als 6 Monate oder Deprecated-Marker im Text; incompatible = fehlende lokale Skript-Referenzen, Binär-Encoding, tote Links, unvollständige Ordner; needs-setup = API-Key-/MCP-/pip-Erwähnung oder vorhandene `requirements.txt`/`package.json`. Badges werden farbig gerendert (stale gelb, incompat rot, setup blau, risk critical/offensive rot).
- **Gruppen:** Keyword-Buckets in fester Priorität (KI-Agents, Cloud/DevOps, Backend/API, Web-Frontend, Game/3D, Automation/SaaS, Content/SEO, Security, Testing, Data/ML, Datenbank, Mobile, Business, Docs/Wiki, Meta-Skills, Health, Personas, Sonstige); erster Treffer gewinnt; Bucket-lose und mehrdeutige Skills gehen als semantischer Fallback an `routed route --json`. Container-Ordner bleiben Sondergruppen.
- **Update-Erkennung (Kernstück):** State-Datei mit Hash und Mtime pro Skill; `fs.watch` mit Debounce; Move-Erkennung über Hash; nach gebündelten Änderungen Mirror-Sync plus `routed reindex`; alle komponenten funktionieren auch ohne Watcher (manueller Rescan).
- **Routed-Integration:** Aufruf über die installierte CLI via PowerShell (pwsh -NoProfile); Fehler werden abgefangen, sodass Analyse, Gruppierung, Mirror und TUI ohne Routed weiterarbeiten; Routed liefert semantische Suche in der TUI und Kategorisierungs-Fallback.
- **Install:** Kopieren (nicht verschieben) in den vom Nutzer eingegebenen Zielpfad; Bestätigungsdialog mit Anzahl und Pfad; Konfliktbehandlung mit Meldung; Zusammenfassung danach; anschließend `routed reindex`.
- **Ablage:** Eigenes Bun-Projekt in einem Unterverzeichnis dieses Repos; Daten-Dateien (skills.json, state.json, copy-manifest.json, REPORT.md) liegen unter dessen data-Ordner; die originale Skills-Bibliothek und ihr Installations-Manifest werden nie verändert.
- **Frontmatter-Parsing:** Kein YAML-Dependency; robuster Zeilen-Parser für die vier relevanten Felder (name, description, category, risk, date_added), getestet gegen die realen Varianten (quoted, unquoted, mit Bindestrich-Datum).

## Testing Decisions

- Gute Tests prüfen nur externes Verhalten: Given eine tmp-Fixture-Ordnerstruktur, liefert die Funktion das erwartete Ergebnis (Index-Inhalt, Klassifizierung, Zielordner nach Sync/Install) – keine internen Aufrufe.
- **Seams:** Die puren Lib-Funktionen (Analyse, Delta-Index) mit injiziertem Skills-Root, getestet gegen tmp-Fixtures (ADR-004). Der ursprüngliche zweite Seam (TUI-Renderer-Tests) ist nach ADR-006 obsolet.
- Watcher-Verhalten wird als Delta-Index-Test geführt (Skill hinzufügen/ändern/löschen/umbenennen → korrekter neuer State), nicht als Timing-Test auf fs.watch.
- Kein Prior-Art im Repo; die PowerShell-Testskripte des Repos decken diesen TypeScript-Teil nicht ab. Lint läuft über Biome (`npm run lint`).

## Abgrenzung / Out of Scope

- **OpenTUI/TUI aller Art** (nach ADR-006 durch skill-manager ersetzt).
- Node.js-Unterstützung (nur Bun).
- Aktives Aufräumen/Ändern/Löschen der Original-Bibliothek durch das Tool.
- Automatisches Aktualisieren von Skills gegen Remote-Quellen (Upstream-Repos).
- Security-Scanning in Eigenregie (SkillSpector deckt das ab; die eigene
  Integration als optionale Risk-Scan-Quelle ist als Issue angelegt).

## Further Notes

- Analysedaten vom ersten Scan (PR #12): 1.872 gültige Skills, 1.144 stale,
  94 incompat, 507 setup; Delta-Test live bestätigt (+2 für neu ergänzte
  PowerShell-Skills).
- 928 Skills haben `risk: unknown` – SkillSpector kann hier eine objektive
  Risk-Bewertung nachliefern (Integration als Issue angelegt).
- Der Skills-Ordner wird weiterhin manuell gesichtet und aufgeräumt – der
  Delta-Index der Analyse-CLI ist dafür die verbleibende Kernanforderung;
  ein Watcher ist nicht mehr geplant (ADR-006).
