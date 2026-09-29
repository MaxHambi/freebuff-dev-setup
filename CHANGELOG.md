# Changelog

Alle nennenswerten Änderungen an diesem Projekt werden in dieser Datei dokumentiert.

Das Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.1.0/)
und dieses Projekt orientiert sich an [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- **Struktur-und-Ordnungs-Mission (2026-09-29, Plan:
  `docs/plan-2026-09-29-struktur-ordnung.md`)**: Closeout der
  ready-for-human-Reste - #30 (Room-Mapping `memory_ingest` in
  `mempalace.yaml`) per Re-Mine- und Suchnachweis geschlossen;
  Issue-Mirror-Index auf den GitHub-Stand korrigiert (#28/#29/#31/#32
  waren bereits geschlossen, nur #30 war noch offen).

- **NextDNS-Manager-Modul (`nextdns-manager/`)**: Onboarding des Desktop-
  Monolith-Scripts als PowerShell-Modul-Projekt (Issues #36-#43, Plan:
  `nextdns-manager/PLAN.md`). Slice 1 (#37): Modul-Geruest (psd1/psm1),
  Setup-Assistent (Vault/Secrets-Pruefung), API-Doku als Repo-Quelle
  (`docs/nextdns-api.md`), Issue-Mirrors #36-#43. Slice 2 (#38): Core-
  API-Schicht mit `200 OK + errors[]`-Fehlerbehandlung, 429/Retry-After,
  Pagination-Dedupe und Limit-Clamps. Slice 3 (#39): Read-Funktionen
  (Logs-Filter status/search/device/from/to/raw/sort), Analytics-Registry
  mit neuen Dimensionen domains/ips (reasons bewusst ohne type,
  destinations mit type-Pflicht), ;series-Support, Full-Report mit
  ohne-Logs-Modus. Slice 4 (#40): Write-Funktionen mit WhatIf/Confirm-
  Schutz (Denylist/Allowlist add/remove, Settings-PATCH, Clear-Logs mit
  ConfirmImpact=High), errors[] je Domain ausgewertet. Slice 5 (#41):
  TUI-Menue und CLI-Parametermodus run.ps1 (Dispatch-Tabelle, Exit-Codes
  0/1/2, Non-Interactive-fest), Nerd-Font-Erkennung mit ASCII-Fallback
  (JetBrainsMono/Meslo/Terminess-Gruppen). Slice 6 (#42): Pester-Suite
  (30 Tests, gemockt) + PSScriptAnalyzer (2 Regelsaetze: Quelle/Tests)
  + Dauer-Smokes (4 Szenarien, 28 Checks, je Smoke eigener Prozess mit
  30-s-Haerte-Timeout) in `scripts/test.ps1` und `npm run verify`
  integriert; explizite Modul-Export-Liste (40 oeffentliche Funktionen,
  Implementierungsdetails bleiben privat); CI installiert Pester 5+/
  PSScriptAnalyzer; Smokes plattformneutral (ASCII-Fallback-Erwartung
  ohne Font-Registry, GetTempPath  statt TEMP). Slice 7 (#43): README
  (Setup/CLI/Architektur/Exit-Codes), PLAN-Befunde mit Erledigt-Status;
  Final-Smoke gegen die Live-API folgt mit Operator-Consent.

- **Repo-Ordnungsrunde (2026-09-26):** `npm run verify` als kanonisches
  Quality-Gate (Lint + tsc + Syntaxcheck + Tests + Doku-Gates; der
  Pre-Push-Hook ruft genau diesen Befehl). Issue-Mirror `docs/issues/`
  (repo-weite Issues #28–#32 gespiegelt; Repo = Quell der Wahrheit).
  GitHub-Hygiene: Repo-Beschreibung/Topics aktualisiert, Issue-Template
  nach Issue-Fibel (`task-fibel.yml`), PR-Template mit Handoff-Muster,
  Dependabot-Config vom leeren Template auf `npm` gefixt. MemPalace-
  Integration auditert und erweitert: L0-Identity repariert, Logstream-
  Sweep dokumentiert (CLI ohne `--preview`), idempotenter Repo-Re-Mine
  (899 → 1003 Drawers), Befunde in `docs/mempalace-audit-2026-09-26.md`,
  verbindliche Agenten-Regeln in `docs/mempalace-regeln.md`.

- **Memory-Ingest-Workflow (`memory-ingest/`)**: wiederverwendbare Session-Ingest-Pipeline,
  die neue Freebuff-Sessions nach Abschluss inkrementell ins Palast-
  Gedächtnis einspeist. Export-Schritt (Bun/TS, read-only gegen die App-DB,
  `lib.ts` als pure Test-Seam nach ADR-004, 16 Unit-Tests gegen tmp-Fixtures)
  mit Live-Schutz per Staleness-Fenster (30 min - die laufende Session wird
  nie exportiert), Mindest-Nachrichtenzahl und State-basiertem Inkrement
  (`memory-ingest-state.json` neben dem Export-Ordner, damit `mine` ihn nicht
  mitliest). Orchestrator `ingest.ps1` (export → `mempalace mine --mode
  convos` → optionaler Such-Selbsttest, Transcript-Log mit Rotation).
  Export-Ordner bewusst = Legacy-Pfad `D:/mempalace/exports/freebuff-legacy-
  sessions`, damit `mine` pro Quellpfad idempotent bleibt (Live-Lauf: 894
  Drawers, kein Duplikat-Schwall). Scheduled Task `MemoryIngest` (taeglich
  04:30 + 4 h) als Runtime-Kopie unter `~/.tools` registriert; XML-Backup in
  `task/MemoryIngest.xml`. `install-task.ps1` kann jetzt wirklich registrieren
  (`-Register` via schtasks, Trigger-Map), `deploy.ps1` ueberschreibt
  Runtime-Logs nie. Entscheidungen dokumentiert als ADR-007 (Scheduled Task
  statt manuellem Mining), ADR-008 (CLI-/STDIO-Fallback + Diagnose-Gate ohne
  MCP-Consent) und ADR-009 (`.mcp.json` projekt-lokal).

### Changed

- **Task-Migration abgeschlossen (plan.md T2-T4, #32)** - Node Watchdog
  registriert (Trigger in `install-task.ps1` auf 10 Min korrigiert),
  NpmCleanup/ToolingCleanup/RoutedWatch auf `%USERPROFILE%\.tools\`
  umgezogen (RoutedWatch vor Move gestoppt inkl. innerem Watcher;
  AtLogon-Registrierung jetzt per-user via `Register-ScheduledTask`, da
  `schtasks /SC ONLOGON` eine any-user-Aufgabe anlegt und Admin verlangt).
  plan.md-Amendment: T5/T6 (NodeProcessMonitor, Ruflo-PolicyLedger-Rotate)
  als alte Reste gestrichen und geloescht (Operator-Entscheidung);
  `maintenance/` und `routed-watch/` wurden aus den Alt-Pfaden ins Repo
  übernommen, XML-Backups aktualisiert, XML-Roundtrip an NpmCleanup
  verifiziert.

- **MemPalace-Diagnose: Consent-Hinweis auf ADR-010-Weg korrigiert (#28, #56)** -
  der WARN-Text von `memory-ingest/check-mempalace.ps1` verweist jetzt auf den
  realen Weg (Server in der Freebuff-UI hinzufuegen - schreibt
  `~/.agents/mcp.json` - nach Neustart freigeben) statt des in dieser
  UI-Version nicht existierenden Projekt-Consent-Prompts; #29 re-gescoped
  mit STDIO-Baseline (search/event_list/kg_query verifiziert, kg-Parameter
  heisst `entity`).

- **Projekt-Umbenennung: `tools-entwicklung` → `freebuff-dev-setup`** (Issues #21-#26) -
  GitHub-Repo (`MaxHambi/freebuff-dev-setup`, Weiterleitung aktiv), lokale
  Remote-URL, Ordner `D:reebuff-dev-setup`, Doku-/Config-Dateien,
  package-Name `freebuff-dev-setup-skills-manager` und 23 PS1-Skripte in
  `.freebuff/skill-extensions/` umgestellt. Claude-Code-Harness-Verweise
  (`CLAUDE.md`-Symlink, `~/.claude.json`, Rules-Identity `maxhambi:claude:*`)
  bleiben bewusst unveraendert. MemPalace-Palast frisch initialisiert (Wing
  `freebuff_dev_setup`, 707 Drawers; Backup unter
  `D:\mempalace\palace-backup-20260925`).

- **Skills-Manager: TUI-Eigenbau verworfen (ADR-006)** - die OpenTUI-Slices
  (#3-#10) sind eingestellt; [skill-manager](https://github.com/abubakarsiddik31/skill-manager)
  (Baum, Multi-Select, Install, Suche) und [SkillSpector](https://github.com/NVIDIA/SkillSpector)
  (Security-Scan, Risk-Score) uebernehmen die Funktionen. Slice 6
  (Delta-Index, #7) gilt als erfuellt (PR #12); Slice 5 (Mirror-Gruppierung,
  #6) bleibt als Backlog offen. package.json: tote Script-Eintrage
  (`group`, `group:dry`, `tui`, `analyze:watch`) entfernt; PRD, PROCESS,
  ARCHITECTURE und Slice-Dokumente auf den neuen Stand gebracht. Die
  Analyse-CLI bleibt Kernstueck; SkillSpector-Integration als neues
  ai-improvement-Issue (TDD) angelegt.

### Added

- Skill-History-Workflow (`skill-history.md` + `scripts/skill-history-log.ps1`):
  protokolliert jede Skill-Ausfuehrung als Eintrag im Changelog-Stil
  (Kontext, Branch@Commit, Quelle, Ergebnis) und versioniert jeden Eintrag
  als eigenen Commit mit dem Label `chore(skill-history):`; registrierbar
  als Session-Hook via `.claude/settings.json` (PostToolUse, Matcher
  `Skill`, `-FromHookJson` parst Skill-Name/Argumente, Fehler blockieren nie);
  README enthaelt die Hook-Landkarte (welcher Hook wo registriert ist -
  `.freebuff/` bietet bewusst kein Hook-Format).
- Doku-Refresh (2026-09-25): README-Skills-Tabelle um 10 neue Skills
  ergaenzt (session-docs-guardian, skill-designer/skill-writer, gm/gm-continue
  mit Issue-#20-Eval-Verweis, WFGY-Suite, agent-memory, aihubmixapi),
  routed-Indexstand auf 2.864 aktualisiert, Hook-Landkarte ergaenzt,
  USER_GUIDE auf ADR-006-Stand gebracht.
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

- AI Blueprint 0.12.5 (Adapter freebuff) eingerichtet und per /onboard
  auf den echten Stack gesetzt: Commands (bun test, syntaxcheck, Gates,
  Deploy-Pipeline), Coding-Standards (Bun/TS + PowerShell statt
  Next.js-Defaults), Branching/Commits (master, Conventional Commits,
  Codebuff-Attribution); blueprint-CLI 1.10.0 global installiert.
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
