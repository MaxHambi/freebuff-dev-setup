# Changelog

Alle nennenswerten Änderungen an diesem Projekt werden in dieser Datei dokumentiert.

Das Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.1.0/)
und dieses Projekt orientiert sich an [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Meta-Skill `using-skills` (`skills/using-skills/`): vereint using-superpowers
  (1%-Gate), using-agent-skills (Phasen-Baum, Operating Behaviors) und
  skill-router (Interview-Funnel); Skill-Discovery ueber routed MCP
  (`route_skill`/`get_skill`/`list_skills`/`scan_skills`) mit deutsch-
  englischer Trigger-Oberflaeche und i18n-Regeln (Body englisch, Antworten
  in der Sprache des Users).
- Automation-Hooks: `route-gate.ps1` (Gate-Enforcement per routed CLI,
  Exit 0/1/2 = kein Skill noetig/Skill-Treffer/Fehler) und `skills-sync.ps1`
  (Aenderungen an den Skills-Ordnern per Snapshot-Diff erkennen und mit
  `routed scan` registrieren; `-Force`/`-HashContent`).
- README-Abschnitt „Lokale Skill-Architektur": routed-Server, MCP-Tools
  (`route_skill`, `get_skill`, `list_skills`, `scan_skills`), Skill-Ablageorte
  (`.gemini`/`.agents`/`.claude`) und Meta-Skill-Gate (superpowers + agent-skills).
- `.gitignore`: `.worktrees/` für lokale isolierte Sitzungs-Worktrees.
- README-Abschnitt „Deploy & Task-Registrierung" mit Helper-Referenz
  (deploy.ps1, install-task.ps1, export-tasks.ps1) und Beispielaufrufen.

### Infrastructure

- Projektgerüst nach plan.md: Slices T1–T7 (Watchdog-Suite, Migration der
  Scheduled Tasks, XML-Backups in `task/`), CI (Biome-Lint + PowerShell-
  Syntaxcheck auf ubuntu/windows), Pre-Push-Gate `scripts/hooks/pre-push`.

### Skills-Manager (Slice 1, PR #12)

- **Analyse-CLI** (#2): Scannt die Skill-Bibliothek, parst SKILL.md-Frontmatter
  ohne YAML-Dependency und klassifiziert jeden Skill nach `stale` (älter als
  6 Monate bzw. Deprecated-/Legacy-Marker), `incompat` (fehlende lokale
  Skript-/Doc-Referenzen, Binär-Anteile) und `needs-setup` (API-Keys,
  MCP-Setup, requirements.txt/package.json).
- **Delta-Index mit Move-Erkennung**: Hash-basierter State erkennt neue,
  geänderte, gelöschte und umbenannte Skills ohne Voll-Rescan – Grundlage
  für das laufende Aufräumen der Bibliothek.
- **Container-Unterstützung**: Gruppen-Container (libreoffice/, security/,
  sendblue/, …) werden rekursiv gelesen; unvollständige Ordner landen im
  Issue-Log statt den Lauf abzubrechen.
- **Report-Artefakte**: maschinenlesbarer Index (`skills.json`), lesbarer
  Report (`REPORT.md`) und Hash-State (`state.json`) unter
  `skills-manager/src/data/` (gitignored).
- **Projektgerüst** (`skills-manager/`): Bun-basiertes Teilprojekt mit
  eigenen Scripts (`analyze`, `tui`, `test`, `lint`), tsconfig und
  OpenTUI-Core-Abhängigkeit für die kommenden TUI-Slices.
- **Issue-Tracker-Konfig** (`docs/agents/`): GitHub Issues als Tracker,
  Triage-Label-Vokabular und Single-Context-Domain-Doku für die
  Engineering-Skills (/to-prd, /to-issues).
- **Planungsartefakte**: PRD (#1) und die neun Tracer-Bullet-Slice-Issues
  (#2–#10) lokal unter `skills-manager/docs/` bzw. `.scratch/` gespiegelt.
- **CI-Workflow** (`.github/workflows/skills-manager.yml`): bun test + Biome-Lint +
  Typecheck auf ubuntu/windows sowie Conventional-Commits- und
  CHANGELOG-Drift-Check (bun-Skripte in `skills-manager/scripts/`).
- **Doku-Ausbau**: README (Skills-Manager, Watchdog, MCP-/Workflows-Details,
  ergaenzte Skills), ADR-002 bis ADR-005, Doku-Landkarte `docs/index.md`,
  Session-Verlauf `docs/sessions.md`, ordner-spezifischer Kontext
  `skills-manager/AGENTS.md`, Root-AGENTS.md aktualisiert (Konvention:
  Ordnerebene-Agent-Dateien heissen AGENTS.md, nie CLAUDE.md)
- **Worktree-Fibel** (`docs/worktree-fibel.md`): Kurzguide zu ADR-003 -
  Wann Worktree, Benennungsschema, PR-Sequenz, Cleanup, Zustandschecks.

### Fixed

- PowerShell-Repo-Scripts (`syntaxcheck`, `deploy`, `install-task`,
  `export-tasks`) in der package.json wiederhergestellt, die beim Anlegen des
  Skills-Manager-Projektgerüsts verloren gegangen waren – das Pre-Push-Gate
  brach daraufhin zu Recht ab.
- npm-Lockfile mit den Bun-Abhängigkeiten (`@opentui/core`, `@types/bun`)
  synchronisiert, damit `npm ci` in der bestehenden CI wieder durchläuft.

### Security

- Generierte Daten-Artefakte (`skills-manager/src/data/`) sind gitignored;
  der Scanner liest die Bibliothek ausschließlich und schreibt nur eigene
  Artefakte im Repo-Worktree.
