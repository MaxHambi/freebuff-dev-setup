#2: Slice 1: Analyse-CLI - Scan, Klassifizierung, Index & Report
<!-- mirror-sync: source=github:MaxHambi/freebuff-dev-setup#2 sha256:gone synced=2026-09-30T06:03:15Z -->

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#2](https://github.com/MaxHambi/freebuff-dev-setup/issues/2).
> Label: `ready-for-agent`. Status: **geschlossen (completed)** — Analyse-CLI geliefert via PR #12 (2026-09-24).

> Detail-Spiegel mit Implementierungsnotizen: [skills-manager/docs/issues/slice-1-analyze-cli.md](../../skills-manager/docs/issues/slice-1-analyze-cli.md) (keine mirror-sync-Header, dokumentierte Abweichung). Raeumungs-Kandidat (C7, 2026-09-30).

## Original-Body

## Parent

#1

## What to build

Tracer Bullet für die Analyse-Pipeline: Ein CLI-Lauf scannt die Skill-Bibliothek, liest pro Skill das Frontmatter (Name, Beschreibung, Kategorie, Risk, Hinzufügedatum) mit einem robusten Zeilen-Parser (kein YAML-Dependency, getestet gegen quoted/unquoted/Datum-Varianten), klassifiziert jeden Skill und schreibt zwei Artefakte: einen maschinenlesbaren Index (JSON) und einen lesbaren Report (Markdown) mit Zahlen pro Status.

Klassifizierung:
- **stale**: `date_added` älter als 6 Monate ODER Deprecated-/Superseded-/Legacy-/Archived-Marker im Text
- **incompatible**: referenzierte lokale Skript-Datei existiert nicht ODER Binär-Encoding im SKILL.md ODER tote relative Doc-Links ODER unvollständiger Ordner (fehlendes SKILL.md)
- **needs-setup**: API-Key-/Token-Erwähnung ODER MCP-Server-Setup ODER `pip install` ODER vorhandene `requirements.txt`/`package.json`

Die Kernlogik (Scannen, Parsen, Klassifizieren) ist als pure Funktionen mit injiziertem Skills-Root gebaut, damit sie gegen tmp-Fixtures testbar sind. Läuft ohne Routed (Fallback: alles ok / keine semantische Anreicherung).

## Acceptance criteria

- [ ] `bun run src/analyze.ts` scannt die echte Bibliothek (~1.858 Skills) in einer akzeptablen Zeit und schreibt Index-JSON + REPORT.md
- [ ] Klassifizierung: ein Skill mit `date_added` 7 Monate alt wird als stale markiert; ein Skill mit `deprecated` im Text ebenfalls
- [ ] Ein Skill, dessen SKILL.md `python scripts/foo.py` referenziert ohne dass `scripts/foo.py` existiert, wird als incompatible markiert
- [ ] Ein Skill mit API-Key-Erwähnung bzw. `requirements.txt` wird als needs-setup markiert
- [ ] Unit-Tests (bun:test) gegen tmp-Fixtures decken Parser-Varianten und alle drei Klassifizierungen ab
- [ ] Ohne konfigurierte Bibliothek bricht das CLI mit verständlicher Fehlermeldung ab
- [ ] `npm run lint` (Biome) bleibt grün

## Blocked by

None - can start immediately
