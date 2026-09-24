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

### Infrastructure

- Projektgerüst nach plan.md: Slices T1–T7 (Watchdog-Suite, Migration der
  Scheduled Tasks, XML-Backups in `task/`), CI (Biome-Lint + PowerShell-
  Syntaxcheck auf ubuntu/windows), Pre-Push-Gate `scripts/hooks/pre-push`.
