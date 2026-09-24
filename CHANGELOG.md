# Changelog

Alle nennenswerten Aenderungen dieses Projekts werden in dieser Datei dokumentiert.

Das Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.1.0/)
und die Versionierung folgt [Semantic Versioning](https://semver.org/lang/de/).

## [Unreleased]

### Added
- **Skills-Manager – Analyse-CLI** (#2, PR #12): Scannt die Skill-Bibliothek,
  parst SKILL.md-Frontmatter ohne YAML-Dependency und klassifiziert jeden Skill
  nach `stale` (aelter als 6 Monate bzw. Deprecated-/Legacy-Marker),
  `incompat` (fehlende lokale Skript-/Doc-Referenzen, Binaer-Anteile) und
  `needs-setup` (API-Keys, MCP-Setup, requirements.txt/package.json).
- **Delta-Index mit Move-Erkennung**: Hash-basierter State erkennt neue,
  geaenderte, geloeschte und umbenannte Skills ohne Voll-Rescan – Grundlage
  fuer das laufende Aufraeumen der Bibliothek.
- **Container-Unterstuetzung**: Gruppen-Container (libreoffice/, security/,
  sendblue/, …) werden rekursiv gelesen; unvollstaendige Ordner landen im
  Issue-Log statt den Lauf abzubrechen.
- **Report-Artefakte**: maschinenlesbarer Index (`skills.json`), lesbarer
  Report (`REPORT.md`) und Hash-State (`state.json`) unter
  `skills-manager/src/data/` (gitignored).
- **Projektgeruest** (`skills-manager/`): Bun-basiertes Teilprojekt mit
  eigenen Scripts (`analyze`, `tui`, `test`, `lint`), tsconfig und
  OpenTUI-Core-Abhaengigkeit fuer die kommenden TUI-Slices.
- **Issue-Tracker-Konfig** (`docs/agents/`): GitHub Issues als Tracker,
  Triage-Label-Vokabular und Single-Context-Domain-Doku fuer die
  Engineering-Skills (/to-prd, /to-issues).
- **Planungsartefakte**: PRD (#1) und die neun Tracer-Bullet-Slice-Issues
  (#2-#10) lokal unter `skills-manager/docs/` bzw. `.scratch/` gespiegelt.
- **CI-Workflow** (`.github/workflows/skills-manager.yml`): bun test + Biome-Lint +
  Typecheck auf ubuntu/windows sowie Conventional-Commits- und
  CHANGELOG-Drift-Check (bun-Skripte in `skills-manager/scripts/`).

### Fixed
- PowerShell-Repo-Scripts (`syntaxcheck`, `deploy`, `install-task`,
  `export-tasks`) in der package.json wiederhergestellt, die beim Anlegen des
  Skills-Manager-Projektgeruests verloren gegangen waren – das Pre-Push-Gate
  brach daraufhin zu Recht ab.
- npm-Lockfile mit den Bun-Abhängigkeiten (`@opentui/core`, `@types/bun`)
  synchronisiert, damit `npm ci` in der bestehenden CI wieder durchläuft.

### Security
- Generierte Daten-Artefakte (`skills-manager/src/data/`) sind gitignored;
  der Scanner liest die Bibliothek ausschliesslich und schreibt nur eigene
  Artefakte im Repo-Worktree.

[Unreleased]: https://github.com/MaxHambi/tools-entwicklung/compare/master...feature/skills-manager
