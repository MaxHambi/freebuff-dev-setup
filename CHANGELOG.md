# Changelog

Alle nennenswerten Änderungen an diesem Projekt werden in dieser Datei dokumentiert.

Das Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.1.0/)
und dieses Projekt orientiert sich an [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

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
