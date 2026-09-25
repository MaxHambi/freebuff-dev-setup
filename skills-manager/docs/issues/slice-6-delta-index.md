## Parent

#1

> **Erfuellt (PR #12, 2026-09-24):** Hash-basierter Delta-Index mit Move-Erkennung, alle vier Deltas (add/change/delete/rename) getestet. Ehrlicher Rest: Der Scan liest weiterhin jede SKILL.md vollstaendig - "nur Deltas neu analysieren" als Perf-Ziel nicht vollstaendig umgesetzt, bei 1.872 Skills unkritisch. Issue #7 als completed geschlossen.

## What to build

Macht die Analyse inkrementell – Grundlage für das Aufräumen im laufenden Betrieb: Eine State-Datei hält pro Skill einen Inhalts-Hash des SKILL.md plus Mtime und Größe. Ein Rescan vergleicht nur Deltas: unveränderte Skills werden nicht neu analysiert, neue analysiert und aufgenommen, geänderte neu klassifiziert, gelöschte entfernt.

- **Move-Erkennung**: Ein Ordner, der unter altem Namen verschwindet und unter neuem Namen mit identischem Hash auftaucht, wird als Umbenennung erkannt (kein Doppel-Eintrag, kein Klassifizierungs-Verlust).
- Der Delta-Lauf aktualisiert Index, State und Report nur für die betroffenen Einträge.
- Die Delta-Logik ist eine pure Lib-Funktion (alter State + Dateisystem-Delta → neuer State + betroffene Liste), testbar ohne Watcher und ohne Timing.

## Acceptance criteria

- [ ] Zweiter Analyse-Lauf ohne Änderungen verändert den Index nicht und ist deutlich schneller als der Erstlauf (nur Hash-Vergleiche)
- [ ] Neuer Skill-Ordner wird beim nächsten Lauf analysiert und aufgenommen
- [ ] Geändertes SKILL.md (z. B. Description) führt zu neu klassifiziertem Eintrag
- [ ] Gelöschter Skill-Ordner wird aus Index, State und Report entfernt
- [ ] Umbenannter Ordner mit gleichem Inhalt wird erkannt (Eintrag unter neuem Namen, alte Klassifizierung erhalten, kein Doppel)
- [ ] Lib-Tests gegen tmp-Fixtures für alle vier Deltas (add/change/delete/rename)

## Blocked by

- #2
