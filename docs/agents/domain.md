# Domain Docs

## Layout: single-context

Dieses Repo hat einen einzigen fachlichen Kontext:

- `AGENTS.md` (Repo-Root) – Projekt-Konventionen und Domain-Vokabular
- `docs/adr/` – existiert noch nicht; Architekturentscheidungen landen dort, wenn sie anfallen

## Consumer-Regeln

Skills, die Domain-Kontext lesen (`improve-codebase-architecture`, `diagnosing-bugs`, `tdd`):

1. Lies `AGENTS.md` für Vokabular und Konventionen (Windows-Tasks, Watchdogs, Deploy nach `%USERPROFILE%\.tools\`, Task-XML-Backups in `task/`).
2. Prüfe `docs/adr/` auf relevante ADRs, bevor du Architekturentscheidungen triffst.
3. Neues Vokabular gehört in `AGENTS.md`, nicht in Skill-Dokumente.
