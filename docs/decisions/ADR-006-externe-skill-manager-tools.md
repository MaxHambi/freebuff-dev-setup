# ADR-006: Externe Skill-Manager-Tools statt Eigenbau-TUI

## Status

Accepted

## Date

2026-09-25

## Context

Der Skills-Manager war als OpenTUI-Terminal-App geplant (PRD #1, Slices
#2–#9): Gruppenbaum, Multi-Select mit Badges, Install-Flow, semantische
Suche via routed, Watcher-Live-Integration. Slice 1 (Analyse-CLI) ist
gemerged (PR #12); die TUI-Slices lagen als Issues #3–#10 bereit.

Seit der Planung haben sich zwei externe Tools gereift, die denselben
Zweck erfuellen:

- **[abubakarsiddik31/skill-manager](https://github.com/abubakarsiddik31/skill-manager)**
  (Desktop-App, MIT): einheitliche Sicht ueber elf Skills-Ordner inkl.
  des geteilten `~/.agents/skills`; Browse und Install aus GitHub-
  Collections, Enable/Disable ohne Loeschen (`.disabled/`-Ordner),
  Edit/Delete, Projekt-Skills, Suche ueber Namen und Beschreibungen.
- **[NVIDIA/SkillSpector](https://github.com/NVIDIA/SkillSpector)**
  (Scanner, Apache-2.0): 71 Vulnerability-Patterns in 17 Kategorien
  (u. a. Prompt Injection, Data Exfiltration), Risk-Score 0–100,
  statischer Modus ohne LLM und API-Keys, Batch-Scan, SARIF/JSON/Markdown.

Zusaetzlich hat sich der Nutzungsmodus geaendert: Die Skill-Bibliothek
wird manuell gesichtet und durchgearbeitet; die interaktive TUI ist dafuer
nicht mehr der Weg. ADR-005 (Mirror statt Move) bleibt gueltig, trifft
aber kuenftig keine Implementierungsentscheidung mehr, solange Slice 5
nicht gebaut wird.

## Decision

1. **Die OpenTUI-Entwicklung wird eingestellt.** Die Slices 2, 3, 4, 8
   und 9 (Issues #3, #4, #5, #8, #9, #10) werden als `wontfix` geschlossen -
   funktional abgedeckt durch skill-manager (Baum/Multi-Select/Install/
   Suche) und SkillSpector (Risk-Bewertung statt reiner Badges).
2. **Slice 6 (Delta-Index, Issue #7) gilt als erfuellt** durch PR #12:
   Hash-basierter State, alle vier Delta-Kinds (add/change/delete/rename)
   mit Tests. Das Perf-Ziel „nur Deltas neu analysieren" ist bewusst
   nicht vollstaendig umgesetzt (der Scan liest weiterhin jede SKILL.md);
   bei 1.872 Skills unkritisch, ein Rest-Risiko nur bei deutlich
   waechsender Bibliothek.
3. **Slice 5 (Mirror-Gruppierung, Issue #6) bleibt als Backlog offen**
   (low priority): Es ist der einzige Baustein ohne externes Aequivalent -
   thematische Gruppenkopie fuer den Datei-Explorer. Ob er je gebaut wird,
   entscheidet der Bedarf beim manuellen Sichten.
4. **Die Analyse-CLI bleibt** Kernstueck des Skills-Manager (Scan,
   Klassifizierung, Index, Report); ihre Klassifizierung (stale/incompat/
   setup) und SkillSpectors Security-Scan sind komplementaer: Die CLI
   beantwortet „was ist veraltet/kaputt/Setup-noeitig", SkillSpector
   beantwortet „ist der Skill gefaehrlich". Die Integration als optionale
   Risk-Scan-Quelle ist als Issue angelegt und wird mit TDD umgesetzt
   (statisch, `--no-llm`, Fallback ohne installierten Scanner).
5. **package.json raeumt auf:** Die Script-Eintrage `group`, `group:dry`,
   `tui` und `analyze:watch` verweisen auf nie gebaute bzw. gestrichene
   Module und werden entfernt; die `@opentui/core`-Abhaendigkeit bleibt
   vorerst unberuehrt, bis Slice 5 entschieden ist (sie ist lokal
   installiert und verursacht keine CI-Last).

## Alternatives Considered

### Eigenbau-TUI fertigstellen (Slices 2–9 wie geplant)
- Pros: Voller Kontrolle, i18n-Trigger, routed-Integration aus einem Guss
- Cons: Mehrere Personenwochen fuer Funktionalitaet, die skill-manager
  heute schon stabil liefert (Desktop-App, elf Tools, Install-Tracking)
- Rejected: Doppelbau gegen ein gepflegtes externes Tool

### Nur SkillSpector, TUI-Features selbst bauen
- Pros: Sicherheits-Scan problemgeloest, Oberflaeche bliebe eigen
- Cons: Genau der teuerste Teil (TUI, Multi-Select, Install-Flow) waere
  weiterhin Eigenbau
- Rejected: Gleiches Argument wie oben

### Analysis-CLI ebenfalls einstellen
- Pros: Kleinstmoeglicher Wartungsbestand
- Cons: Kein anderes Tool liefert das Repo-eigene Delta-Format
  (Move-Erkennung, maschinenlesbarer Index, REPORT.md) und die
  Bibliotheks-Gesundheitszahlen; der vorhandene Code ist getestet und
  gemerged
- Rejected: Die CLI ist der nachhaltige Eigenwert des Skills-Manager

## Consequences

- Issues #3, #4, #5, #8, #9, #10 werden mit Verweis auf dieses ADR und
  auf die beiden externen Tools geschlossen (`wontfix`, not planned).
- Issue #7 wird als completed geschlossen (PR #12) mit dem ehrlichen
  Hinweis auf das Rest-Perf-Ziel.
- Issue #1 (PRD-Umbrella) wird als superseded geschlossen; PRD und
  PROCESS beschreiben ab sofort nur noch die realisierte bzw. offene
  Rest-Scope (Analyse-CLI, optionaler SkillSpector-Scan, Mirror-Backlog).
- Ein neues Issue bennent die SkillSpector-Integration (ai-improvement,
  `ready-for-agent`, TDD-Methodik).
- Doku-Anpassungen: README (Skills-Manager-Abschnitt), PRD, PROCESS
  (Issue-Map), INDEX, slice-2..9-Dokumente mit Superseded-Vermerk.
- Tests/Lint/CI bleiben unveraendert gruene Gates (25 bun-Tests, Biome,
  tsc, Conventional Commits, CHANGELOG-Drift-Check).

## Related

- PRD #1 (Problem Statement, 33 User Stories - hier weitgehend ersetzt)
- Issues #3–#10 (Slice-Issues; Schicksal oben je Slice entschieden)
- ADR-005 (Mirror statt Move - fuer Slice 5 Backlog weiter gueltig)
- ADR-002 (routed scan_skills als massgeblicher Index - unveraendert)
- [skill-manager](https://github.com/abubakarsiddik31/skill-manager),
  [SkillSpector](https://github.com/NVIDIA/SkillSpector)
