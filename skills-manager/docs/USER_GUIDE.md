# User Guide: Skills-Manager

Anleitung fuer die Nutzung des Analyse-CLIs (Stand: Slice 1). Die TUI folgt mit Slice 2+.

## Voraussetzungen

- [Bun](https://bun.sh) 1.3.0 oder neuer (`bun --version`)
- Die Skill-Bibliothek unter `%USERPROFILE%\.agents\skills\` (Standard-Root)

## Installation / Setup

```powershell
# Im Worktree oder Repo-Root
bun install
```

Das war alles – keine globalen Abhängigkeiten.

## Analyse ausführen

```powershell
bun run skills-manager/src/analyze.ts
```

Standardmäßig wird `%USERPROFILE%\.agents\skills\` analysiert. Anderen Root angeben:

```powershell
bun run skills-manager/src/analyze.ts --root D:\meine-skills
```

Konsole schlau halten (z. B. in Skripten):

```powershell
bun run skills-manager/src/analyze.ts --quiet
```

### Was passiert?

1. Erster Lauf: scannt **alle** Skills und schreibt den Initial-State.
2. Folgelauf: vergleicht nur Deltas – neue/geänderte/gelöschte/umbenannte Skills
   werden erkannt, der Rest bleibt unangetastet (schnell bei 1.800+ Skills).

Beispiel-Ausgabe:

```
Analysiere: C:\Users\Max Hambi\.agents\skills
Delta: +2 neu, ~0 geaendert, -0 geloescht, => 0 umbenannt, 1872 unveraendert
Index: 1874 Skills (stale: 1145, incompat: 95, setup: 507)
```

## Ergebnisse lesen

Alle Artefakte liegen unter `skills-manager/src/data/` (gitignored):

| Datei | Inhalt |
|-------|--------|
| `skills.json` | Maschinenlesbarer Index: pro Skill Name, Beschreibung, Risiko, Flags, Gründe, Hash |
| `REPORT.md` | Lesbarer Report: Kopfzahlen, Risiko-Verteilung, Container-Übersicht, Flag-Auszug |
| `state.json` | Hash-State für den nächsten Delta-Lauf (nicht für Menschen gedacht) |

### Die Badges

| Badge | Bedeutung | Typische Reaktion |
|-------|-----------|-------------------|
| `stale` | älter als 6 Monate oder Deprecated-/Legacy-Marker | Inhalt kritisch prüfen, ggf. Upstream prüfen |
| `incompat` | fehlende Skript-/Doc-Referenzen oder Binär-Anteile | Skill ist vermutlich kaputt – vor Nutzung reparieren |
| `setup` | braucht API-Keys, MCP-Server oder Python-/Node-Pakete | Setup-Abschnitt im SKILL.md lesen, bevor man den Skill nutzt |

## Tests & Lint

```powershell
bun test          # 25 Unit-/Integrationstests gegen tmp-Fixtures
bunx tsc --noEmit # Typcheck
npx biome lint skills-manager  # Lint
```

## Troubleshooting

| Problem | Lösung |
|---------|--------|
| `Skills-Root nicht lesbar: ...` | Pfad prüfen; mit `--root <pfad>` den korrekten Ordner angeben |
| Zahlen wirken zu hoch bei `stale` | Die Bibliothek ist zwischen Februar und Juli 2026 befüllt worden; bei Stichtags-Überschreitung rutscht der ganze Jahrgang. Schwelle liegt in `classify.ts` (`STALE_MONTHS = 6`) |
| Ich will den Zustand zurücksetzen | `skills-manager/src/data/state.json` löschen – der nächste Lauf ist wieder ein Voll-Scan |

## Nächste Schritte

- Slice 2 (Issue #3): TUI mit Gruppenbaum und Beschreibungspanel
- Slice 5 (Issue #6): thematischer Mirror unter `~/.agents/skills-org/`
