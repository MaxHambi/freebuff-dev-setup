# freebuff-dev-setup

Windows Scheduled Tasks & Watchdogs as code - plus Skills-Manager fuer die
persoenliche Agent-Skills-Bibliothek und Memory-Ingest fuer das
MemPalace-Gedaechtnis.

**Inhalt:** [Skills-Manager](#skills-manager-skills-manager) · [Node-Watchdog](#node-watchdog-node-watchdog) · [Memory-Ingest](#memory-ingest-memory-ingest) · [Skills-Verzeichnis](#skills-verzeichnis-skills) · [Lokale Skill-Architektur](#lokale-skill-architektur) · [Deploy & Task-Registrierung](#deploy--task-registrierung-scripts-) · [Task-Regel: run-hidden.vbs](#task-regel-task-aktionen-laufen-ueber-run-hiddenvbs) · [Qualitätsgate](#qualitätsgate)

| Bereich | Inhalt | Doku |
|---------|--------|------|
| `plan.md` | Masterplan (Slices T1–T7): T1 erfuellt, T2–T6 offen (Abgleich 2026-09-26 im Plan - Alt-Tasks laufen noch auf den urspruenglichen Pfaden) | - |
| `node-watchdog/` | Globaler Node/Electron/esbuild-Watchdog (DryRun-Default, Whitelist, Baum-Kill, Log-Rotation) | ADR-001 |
| `skills-manager/` | Analyse-CLI fuer `~/.agents/skills` (Slice 1 gemerged; TUI-Slices via ADR-006 verworfen) | `skills-manager/docs/` |
| `memory-ingest/` | Session → Palast-Ingest (Scheduled Task `MemoryIngest`, Staleness-Live-Schutz, State-Inkrement, Diagnose-Script) | ADR-007, README-Abschnitt unten |
| `skills/` | Eigene Agent Skills (Meta-Skill `using-skills` mit Gate + Router + Hooks) | unten, Abschnitt Skills-Verzeichnis |
| `task/` | Exportierte Task-XMLs aller eigenen Scheduled Tasks (GUI-Backup) | unten, Wiederherstellung |
| `docs/decisions/` | Architekturentscheidungen als ADRs (ADR-001 bis ADR-011) | `docs/index.md` |
| `scripts/` | Deploy-/Registrierungs-Helper + Quality-Gate (`npm run verify`) | unten, Deploy & Task-Registrierung |

## Skills-Manager (`skills-manager/`)

Bun-basiertes Werkzeug fuer die persoenliche Skill-Bibliothek
(`%USERPROFILE%.agentsskills`, ueber 1.800 Skills). Slice 1 (Analyse-CLI)
ist gemerged; die TUI-Slices sind via ADR-006 verworfen - die externen
Tools [skill-manager](https://github.com/abubakarsiddik31/skill-manager)
(Baum, Multi-Select, Install, Suche) und [SkillSpector](https://github.com/NVIDIA/SkillSpector)
(Security-Scan, Risk-Score) uebernehmen die Funktionen.

### Analyse-CLI (Slice 1, gemerged via PR #12)

```powershell
bun run skills-manager/src/analyze.ts            # Standard-Root analysieren
bun run skills-manager/src/analyze.ts --root <pfad> --quiet
```

- Klassifiziert jeden Skill: `stale` (aelter als 6 Monate bzw. Deprecated-Marker),
  `incompat` (fehlende lokale Skript-/Doc-Referenzen, Binaer-Anteile),
  `setup` (API-Keys, MCP-Server, requirements.txt/package.json)
- Erkennt Container-Ordner (libreoffice/, security/, sendblue/) rekursiv
- Delta-Index mit Move-Erkennung: Folgelauf prueft nur Aenderungen
- Erstlauf gegen die echte Bibliothek: 1.872 Skills -> 1.144 stale, 94 incompat, 507 setup
- Artefakte in `skills-manager/src/data/` (gitignored): `skills.json`,
  `REPORT.md`, `state.json`

### Test-Gates

```powershell
bun test                                    # 25 Tests gegen tmp-Fixtures
bunx tsc --noEmit                           # Typcheck
bun run skills-manager/scripts/check-commits.ts --base origin/master
bun run skills-manager/scripts/check-changelog.ts --base origin/master
```

Beide Check-Skripte laufen im CI-Workflow `.github/workflows/skills-manager.yml`
(test + lint + typecheck auf ubuntu/windows) und erzwingen Conventional
Commits sowie einen aktuellen `[Unreleased]`-Abschnitt im CHANGELOG.

### Stand nach ADR-006 (2026-09-25)

| Slice | Issue | Status |
|-------|-------|--------|
| 1 Analyse-CLI | #2 | erledigt (PR #12) |
| 2-4, 8-9 TUI-Funktionen | #3-#5, #8-#10 | wontfix - extern: skill-manager + SkillSpector |
| 5 Mirror-Gruppierung | #6 | Backlog (low priority) |
| 6 Delta-Index | #7 | erledigt (PR #12) |

Naechste Aufgabe: SkillSpector-Integration als optionale Risk-Scan-Quelle
(ai-improvement-Issue, TDD). Details: `skills-manager/docs/INDEX.md`
(Einstieg), PRD, Architektur, API-Referenz und User Guide liegen daneben.
## Node-Watchdog (`node-watchdog/`)

Globaler Watchdog fuer `node.exe`/`electron.exe`/`esbuild.exe` (Slice T1,
gemerged via PR #13). Kern: drei Kill-Kriterien - orphan (mit PID-Reuse-
Schutz ueber Eltern-Startzeit), idle-aged (Alter UND CPU-Zeit), stale-port
(netstat-Mapping). DryRun ist Default; Kills nur mit `-Apply`.

```powershell
pwsh -File node-watchdog/node-watchdog.ps1              # DryRun-Report
pwsh -File node-watchdog/run-tests.ps1                  # Integrationstests (18/22 PASS)
```

- Whitelist per Substring gegen CommandLine+ExecutablePath (`whitelist.txt`)
- Selbstschutz (eigene Elternkette), Baum-Kill via `taskkill /T /F`
- Log-Rotation ab 5 MB (3 Archive)
- 4 Known-Fails im Harness sind dokumentiert in ADR-001 (Status offen,
  Verifikation als Issue #14)

## Memory-Ingest (`memory-ingest/`)

Inkrementeller Speise-Pipeline: neue Freebuff-Sessions (Threads aus der
Desktop-DB) werden nach Abschluss als Markdown-Transcripte exportiert und per
`mempalace mine` ins Palast-Gedaechtnis gefilmt - Entscheidungen, Probleme,
Meilensteine und User-Input inklusive Freebuff-Reaktion. Ausgelegt als
Scheduled Task `MemoryIngest` (Default: taeglich 04:30, alle 4 h).

Kern-Eigenschaften:

- **Read-only**: die App-DB (`desktop-v2.db`) wird nur gelesen, nie geschrieben
- **Live-Schutz**: Threads, die jünger als 30 min aktualisiert wurden, bleiben
  draussen (Staleness-Fenster) - die laufende Session wird nie exportiert
- **Inkrementell**: Hash-artiger State (`memory-ingest-state.json`, liegt
  neben dem Export-Ordner) erkennt neue/veraenderte Threads; Unveraendertes
  wird uebersprungen
- **Idempotent im Palast**: Export-Ordner bewusst = Legacy-Pfad
  (`D:/mempalace/exports/freebuff-legacy-sessions`), damit `mine` pro Quellpfad
  keine Duplikate filmt
- **Mine-Filter**: `--min-messages 2` (Ein-Speech-Threads interessieren nicht)
- **DryRun-Default** im Export-Schritt (`--dry-run` bzw. `-DryRun` im
  Orchestrator)

```powershell
pwsh -File memory-ingest/ingest.ps1                       # export + mine
pwsh -File memory-ingest/ingest.ps1 -DryRun               # nur Export-Plan
pwsh -File memory-ingest/ingest.ps1 -VerifyQuery "adr"    # Such-Selbsttest
pwsh -File memory-ingest/ingest.ps1 -IncludeThread <id>   # Live-Schutz uebersteuern
bun test memory-ingest                                    # 16 Unit-Tests
```

Diagnose der MemPalace-Anbindung (Consent-State, Binary-Smoke, Palast-Suche)
in einem Lauf - Exit 0 gruen / 1 harter Fehler / 2 nur Consent fehlt:

```powershell
pwsh -File memory-ingest/check-mempalace.ps1              # Standard-Diagnose
pwsh -File memory-ingest/check-mempalace.ps1 -Query "adr" # eigene Test-Query
```

Wartung: Log-Rotation ab 5 MB (`ingest.log.1`); `deploy.ps1` ueberschreibt
Runtime-Logs nicht. Wenn der State-JSON versehentlich im Export-Ordner landet
(alte Version), filmt `mine` ihn als `_registry`-Eintrag - dann per
`mempalace_delete_by_source` (MCP) oder den State neben den Ordner legen.

## Skills-Verzeichnis (`skills/`)

Das Repo versioniert eigene Agent Skills unter `skills/`; Deploy-Ziel ist
`%USERPROFILE%\.agents\skills\<name>\` (Registrierung im routed-Index nur
noch via MCP `scan_skills` — upsert-only, kein Prune).

### skills/using-skills — Meta-Skill (Gate + Router)

Vereint das 1%-Skill-Gate (using-superpowers), den Phasen-Baum (using-agent-skills)
und den Interview-Funnel (skill-router); Discovery-Fallback ueber routed MCP.

| Artefakt | Zweck |
|---|---|
| `SKILL.md` | Gate → Router → Interview → routed-Discovery → Operating Behaviors; i18n-Regeln (deutsch-englische Trigger-Description) |
| `references/routing-reference.md` | Vollstaendiger Phasen-Baum, Kategorie-Routing, Interview-Funnel, Lifecycle |
| `references/routed-mcp.md` | MCP-Tool-Signaturen, Standard-Workflow, CLI-Fallback, Fehlersignaturen |
| `hooks/route-gate.ps1` | Gate-Enforcement per routed CLI. Exit `0` = kein Skill noetig, `1` = Skill-Treffer einladen, `2` = routed nicht erreichbar |
| `hooks/skills-sync.ps1` | **stillgelegt (Issue #15, C1, 2026-09-30)**: `routed scan` pruned den Index global (live bewiesen 2026-09-29: −2512 Rows), die User-Bibliothek `~/.agents/skills` fehlt im Detector — der Hook liefert einen lauteren Exit 0 mit Hinweis statt zu scannen. Re-Enable-Kriterien stehen im Dateikopf; Registrierung nur via routed MCP `scan_skills` (ADR-002) |

Hooks ausfuehren:

```powershell
pwsh -File skills/using-skills/hooks/route-gate.ps1 -Prompt "<task>"
# skills-sync.ps1 ist stillgelegt (Issue #15/C1) - Index-Registrierung via routed MCP `scan_skills`
```

Index-Registrierung: Aenderungen an Skills immer am Deploy-Ziel und im Repo
pflegen, danach MCP `scan_skills` (upsert-only).

## Agent-Doku-Konvention (AGENTS.md)

Ordnerebene-Agent-Dateien heissen in diesem Repo **immer** `AGENTS.md` -
keine `CLAUDE.md` (Root-`CLAUDE.md` ist nur ein lokaler, gitignored Symlink).
Betroffen: Root-`AGENTS.md` (Konventionen, Commands) und
`skills-manager/AGENTS.md` (ordner-spezifischer Kontext). Session-Ende:
Skill `session-docs-guardian` prueft beide als eigene Doku-Ziele.

## Skill-History (`skill-history.md`)

Changelog jeder Skill-Ausfuehrung in dieser Session/Repo - ein Eintrag pro
gestartetem Skill (Kontext, Branch@Commit, Quelle, Ergebnis), neuester oben.
Jeder Eintrag wird als eigener Commit mit dem Label `chore(skill-history):`
versioniert, damit Skill-Nutzung und Code-Aenderungen getrennt bleiben.

```powershell
# Manuell protokollieren:
pwsh -File scripts/skill-history-log.ps1 -SkillName "<name>" `
     -Detail "<kontext>" -Ergebnis "<fazit>"

# Nur Eintrag, kein Commit:
pwsh -File scripts/skill-history-log.ps1 -SkillName "<name>" -NoCommit
```

Session-Hook: `.claude/settings.json` registriert `scripts/skill-history-log.ps1`
als PostToolUse-Hook (Matcher `Skill`); das Hook-JSON liefert Skill-Name und
Argumente, `-FromHookJson` parst sie. Hook-Fehler blockieren die Session nie.

### Hook-Landkarte

Welcher Hook lebt wo, was loest ihn aus, welcher ist (noch) nicht aktiv:

| Hook | Ort | Ausloeser | Status |
|------|-----|-----------|--------|
| `scripts/hooks/pre-push` (Quality-Gate) | Git `core.hooksPath=scripts/hooks` | `git push` | **aktiv** - ruft `npm run verify` (Lint, tsc, Syntaxcheck, Konventions-Wächter, Tests, Drift-Checks) |
| `scripts/skill-history-log.ps1` | `.claude/settings.json` (Repo) | PostToolUse, Matcher `Skill` | **nicht registriert** (bewusst offen; `.claude/settings.json` existiert im Repo nicht — Ghost-Claim „aktiv" in der Doku korrigiert; Registrierung ist ein Operator-Entscheid, Anleitung im Skriptkopf) |
| `context-trim/analyze.js` | `~/.claude/settings.json` (User) | PostToolUse, Matcher `Write\|Edit` | aktiv (externes Tool, nicht Teil des Repos) |
| `session-end.ps1` (session-docs-guardian) | `~/.claude/settings.json` vorgesehen | SessionEnd/Stop | **bewusst nicht registriert (Operator-Entscheid 2026-09-29)** — End-of-Session-Doku-Audit läuft skill-getrieben im Session-Closeout; Anleitung bleibt: `~/.agents/skills/session-docs-guardian/hooks/register-hook.md` |
| `route-gate.ps1` / `skills-sync.ps1` | `skills/using-skills/hooks/` | manuell (`pwsh -File ...`) bzw. routed MCP | skills-sync **stillgelegt** (Issue #15/C1: `routed scan`-Prune-Risiko, Re-Enable im Dateikopf); route-gate manuell - bewusst keine Session-Auto-Registrierung |
| `node-watchdog.ps1` | Windows Scheduled Tasks (Slices T2+, `plan.md`) | Zeitplan | Betrieb statt Hook |
| `scripts/agenttrace-audit.ps1` | Git `core.hooksPath=scripts/hooks` (via pre-push), manuell: `npm run audit:sessions` | vor jedem Push | **advisory** - agenttrace-Health-Bericht nach `out/agenttrace-overview.md` (gitignored); warnt bei Health unter 70 oder kritischen Anomalien, blockiert nie. Skip, wenn die Binary fehlt; abschaltbar mit `AGENTTRACE_AUDIT=0` |

Hinweis: **`.freebuff/` bietet kein Hook-Format** - der Ordner traegt nur
die `project-id` und `skill-extensions/` (Sitzungs-Scratch, nie Quelle der
Wahrheit, siehe Worktree-Fibel). Hook-Registrierung fuer Freebuff-Sessions
laeuft ueber `.claude/settings.json` im Repo bzw. `~/.claude/settings.json`
fuer den Nutzer.

## Wiederherstellung eines Tasks (GUI)

1. Aufgabenplanung öffnen (`taskschd.msc`)
2. „Aufgabe importieren…"
3. XML aus `task/` wählen (enthält absolute Pfade dieses Rechners – ggf. Aktionspfad anpassen)

## Lokale Skill-Architektur

Repo-unabhängige Infrastruktur auf diesem Rechner – hier nur zur Orientierung,
die Wartung erfolgt außerhalb des Repos.

### routed (Skill-Routing-Server)

- Installiert unter `%LOCALAPPDATA%\Programs\Routed\bin\routed.cmd`, Version
  wird mit `routed --version` geprüft.
- Indexiert Skills über alle Tool-Hosts hinweg in einer lokalen SQLite-DB
  (`routed scan_skills`; Stand 2026-09-29: **436 indexiert** — Discovery-Lücke
  der aktuellen routed-Version dokumentiert in #15: 1968 SKILL.md in der
  User-Bibliothek, CLI-Scan sieht sie nicht).
- **MCP-Tools** (konfiguriert in `.cline/mcp_settings.json`, Server `routed`):
  `route_skill` (Prompt → bester Skill), `get_skill` (SKILL.md nach ID/Name),
  `list_skills` (Index durchsuchen), `scan_skills` (Index neu aufbauen).
- **CLI:** `routed route --json "<prompt>"` → JSON mit `selectedSkills`
  inkl. `path` auf die `SKILL.md` (dann direkt lesen).
- Vor fachlicher Arbeit routen: Workflow `.cline/workflows/route.md` (`/route <prompt>`).

### Ablageorte der Skill-Dateien

| Ort | Rolle |
|---|---|
| `%USERPROFILE%\.gemini\config\plugins\<plugin>\skills\` | Canonical-Kopien der Plugins (agent-skills, superpowers); routed indexiert diese Pfade |
| `%USERPROFILE%\.agents\skills\` | tool-übergreifende Kopien (teils mit zusätzlichem Metadaten-Frontmatter) |
| `%USERPROFILE%\.claude\skills\` | Claude-Code-eigene Skills |
| `%LOCALAPPDATA%\Routed\` | routed-Binary + eigener Index |

Änderungen an Skills immer an **beiden** Orten pflegen (canonical + Kopie) und
danach `scan_skills` ausführen, sonst liefert routed veraltete Fassungen aus.

### Meta-Skill-Gate

Zwei Meta-Skills arbeiten zusammen und ergänzen sich:

- **`using-superpowers`** = Gate (WANN?): 1 %-Regel – sobald ein Skill auch nur
  entfernt relevant sein könnte, ihn vor der ersten Antwort/aktion aufrufen;
  Red-Flags-Tabelle gegen Rationalisierung; Plattform-Adaption; User-Instructions
  (AGENTS.md & Co.) haben Vorrang vor Skills.
- **`using-agent-skills`** = Router (WELCHER/WIE?): Entwicklungsphasen-Baum
  (Define → Plan → Build → Verify → Review → Ship), Operating Behaviors
  (Annahmen offenlegen, Confusion stoppen, Pushback, Einfachheit, Scope,
  Verifikation), Lifecycle-Sequenz.
- Ablauf: Gate prüft (superpowers) → Router wählt (agent-skills) → gefundene
  Skills fehlen? Routed-Fallback → Skill folgt exakt, ist aber kein Gehorsam:
  bei falscher Prämisse verwerfen und ohne weiterarbeiten.

### MCP-Server & Workflows (`.cline/`)

Der routed MCP-Server ist in `.cline/mcp_settings.json` konfiguriert
(lokale Infrastruktur, repo-unabhaengig):

| Einstellung | Wert |
|---|---|
| Server | `routed` (Command `routed mcp`) |
| Auto-Approve | `route_skill`, `get_skill`, `list_skills` |
| Manuell freigegeben | `scan_skills` (Index-Rebuild, schreibend) |

Workflow `.cline/workflows/route.md` (`/route <prompt>`): vor fachlicher
Arbeit `route_skill` aufrufen; bei Treffern die SKILL.md am gelieferten
`path` lesen und befolgen; ohne Treffer direkt arbeiten.

### Eigene und ergaenzte Skills (Stand nach PR #11/#12/#13)

| Skill | Herkunft | Inhalt |
|---|---|---|
| `using-skills` | eigenes Repo (`skills/using-skills/`) | Meta-Skill: Gate + Router + Interview + routed-Discovery + Hooks (s. o.) |
| `powershell-script-engine` | manuell ergaenzt | PowerShell/Windows-Systemtechnik-Experte (Bibliothek) |
| `powershell-script-authoring` | manuell ergaenzt | PowerShell-Skripte erstellen, pruefen, paketieren |
| `opentui` | installiert | Terminal-UIs mit OpenTUI (Core/React/Solid, Renderer-APIs) - historisch (TUI via ADR-006 verworfen, Dep bleibt bis Backlog-Entscheid) |
| `to-prd`, `to-issues`, `setup-matt-pocock-skills` | installiert (mattpocock/skills) | PRD-/Issue-Workflows mit GitHub-Tracker und Triage-Labels |
| `git-pr-workflows-git-workflow`, `git-pr-workflows-pr-enhance` | installiert + Repo-Scope (`.agents/skills/`, ADR-012) | Conventional-Commits-, Branch- und PR-Pipeline |
| `changelog-automation`, `documentation-and-adrs`, `documentation-generation-doc-generate` | installiert | Changelog (Keep a Changelog), ADR- und Doku-Generierung |
| `interview-style-doc-building`, `brain-to-docs`, `code-documentation-doc-generate` | installiert | Interviewbasierte Doku-Erstellung (eine Frage pro Antwort, Patch statt Overwrite; README+ADR aus Vision) |
| `skill-designer` (+ `skill-writer` als Deep-Referenz) | installiert | Canonical-Workflow fuer Skill-Authoring; skill-writer liefert evaluation-path und description-optimization |
| `session-docs-guardian` | eigenes Repo (`.agents/skills/session-docs-guardian/`, ADR-012) | End-of-Session-Doku-Audit: AGENTS/CHANGELOG/ADR/README-Stale-Pruefung, Session-Summary, Skill-Registrierung; Hook `hooks/session-end.ps1` bewusst nicht registriert (Operator-Entscheid 2026-09-29, siehe Hook-Landkarte) |
| `gm`, `gm-continue` | installiert (nur User-Level; Repo-Kopien per ADR-012 entfernt) - **Eval offen (Issue #20)** | Verb-Daemon-Treiber mit eigener Runtime (`agentplug-runner.exe`, `plugkit.wasm`); Nutzung erst nach Eval-Empfehlung |
| `wfgy-method`, `polaris-protocol`, `polaris-goal-compiler`, `fifth-dimension-engine` | installiert | WFGY 5.0 Reasoning-Disziplin: Drift-Reduktion, Goal-Compiler, Problem-Routen |
| `agent-memory` | installiert | TencentDB Agent Memory (MemoryCore/MemoryHub/MemoryProxy/MemoryPanel) - persistenter Cross-Session-Speicher |
| `aihubmixapi` | installiert | AIHubMix-API-Integration: SDK-Code, Modellwahl, Live-Quellen |
| `agents-md`, `analyze-project`, `brainstorming`, `idea-refine`, `security-bluebook-builder` | Repo-Scope (`.agents/skills/`, ADR-012) | Session-/Projekt-Skills ohne User-Level-Kopie: Agent-Doku-Schlankeit, Session-/Repo-Analyse, Ideenausarbeitung, Security-Dossier |
| `git-advanced-workflows`, `github`, `github-actions-advanced`, `github-actions-templates`, `github-presence`, `github-workflow-automation`, `gitops-workflow`, `blueprint` | Repo-Scope (`.agents/skills/`, ADR-012) | Git/GitHub-Workflows + Multi-PR-Bauplan-Generator (blueprint) |

Deploy-Ziel eigener Skills: `%USERPROFILE%.agentsskills<name>`, danach
MCP `scan_skills` (siehe ADR-002: `scan_skills` ist der massgebliche
Indexierungsweg; `skills-sync.ps1` ist stillgelegt, Issue #15/C1).

## Deploy & Task-Registrierung (`scripts/`)

Die Helper bilden die Pipeline Repo → Runtime → Task-Registrierung → XML-Backup.
Reihenfolge: erst `deploy`, dann `install-task`, dann `export-tasks`.

| Helper | Zweck |
|---|---|
| `scripts/deploy.ps1` | Spiegelt die Task-Ordner (`node-watchdog`, `maintenance`, `routed-watch`, `memory-ingest`) nach `%USERPROFILE%\.tools`. Merge-Logik: existierende Dateien bleiben stehen (`KEEP`), Überschreiben nur mit `-Force` (`COPY`). `*.log`-Dateien werden nie kopiert (gehören der laufenden Task). Noch nicht vorhandene Ordner werden übersprungen (`SKIP`). |
| `scripts/install-task.ps1` | Registriert Scheduled Tasks auf die Runtime-Pfade. Task-Auswahl per `-Task` (bekannt: `Node Watchdog`, `NpmCleanup`, `ToolingCleanup`, `RoutedWatch`, `MemoryIngest`), echtes Anlegen/Überschreiben nur mit `-Register` (schtasks, `MemoryIngest` = taeglich 04:30 + 4 h-Wiederholung; AtLogon per-user via `Register-ScheduledTask`). Ohne `-Register` nur Vorschau von Aktion und Trigger. |
| `scripts/export-tasks.ps1` | Sichert registrierte Tasks als XML nach `task\<Name>.xml` (`schtasks /query /tn <name> /xml`). Nicht registrierte Tasks → `SKIP`. Diese XMLs sind das Backup für die GUI-Wiederherstellung (siehe oben). `task/Ruflo-PolicyLedger-Rotate-workspace.xml` ist ein bewusstes Archiv des 2026-09-29 deregistrierten Fremd-Tasks (plan.md-Amendment) und wird nicht überschrieben. |

Beispielaufrufe:

```powershell
# 1) Runtime-Kopien nach %USERPROFILE%\.tools spiegeln (bestehende Dateien bleiben erhalten)
pwsh -File scripts/deploy.ps1

# Repo-Stand durchsetzen (alle Zieldateien ueberschreiben)
pwsh -File scripts/deploy.ps1 -Force

# 2) Task registrieren - Aktion zeigt auf den Runtime-Pfad, nicht ins Repo
pwsh -File scripts/install-task.ps1 -Task "Node Watchdog"          # Vorschau
pwsh -File scripts/install-task.ps1 -Task MemoryIngest -Register   # echtes Anlegen/Update

# 3) Task-Definition als XML sichern (Backup fuer GUI-Import)
pwsh -File scripts/export-tasks.ps1
```

Offene Arbeiten und ihre Reihenfolge: [docs/ROADMAP.md](docs/ROADMAP.md).

Konventionen: Runtime-Pfade zeigen immer auf `%USERPROFILE%\.tools`, nie ins Repo.
Die exportierten XMLs enthalten absolute Pfade dieses Rechners und dienen nur als
Backup - nie als Installationsquelle. Destruktive Schritte (Überschreiben mit
`-Force`, Task-Neuregistrierung) erst nach einem Report-/DryRun-Lauf ausführen.

## Task-Regel: Task-Aktionen laufen ueber run-hidden.vbs

**Regel:** Jede Aktion eines Scheduled Tasks in dieser Suite startet das
PowerShell-Skript niemals direkt, sondern immer ueber den Wrapper:

```text
wscript.exe //B //Nologo "%USERPROFILE%\.tools\maintenance\run-hidden.vbs" "<skript.ps1>" [argumente]
```

**Warum:** PowerShell ist eine Konsolenanwendung; Windows erzeugt das
conhost-Fenster, bevor der Schalter `-WindowStyle Hidden` verarbeitet wird -
der Flash war also schon passiert, wenn PowerShell ihn versteckt haette.
`WScript.Shell.Run cmd, 0, True` (SW_HIDE) startet den Kindprozess ab dem
ersten Befehl ohne Fenster; `//B //Nologo` haelt auch wscript selbst still.
Der Wrapper reicht alle Argumente gequoted durch (inkl. Watchdog-`-Apply`)
und wartet synchron, damit ExecutionTimeLimit und IgnoreNew weiter greifen.

**Durchsetzung:**

- `scripts/install-task.ps1` erzeugt nur noch Wrapper-Aktionen - neue
  Registrierungen koennen den Fehler nicht wieder einfuehren.
- Die XML-Backups in `task/` zeigen `<Command>wscript.exe</Command>`; bei
  manueller GUI-Wiederherstellung gilt der Wrapper unverändert.
- Migration bestehender Tasks nur per XML-Round-Trip: Command/Arguments
  patchen, Trigger/Principal/Settings byte-identisch lassen.

**Verifikation:** `Get-ScheduledTaskInfo` (LastTaskResult) plus die
aktivierte TaskScheduler-Operational-Historie; die Beweiskette der
Ursache und der Migration liegt in
[audit/2026-10-01-fenster-flash/](audit/2026-10-01-fenster-flash/00-INDEX.md)
(Protokoll, Entscheidungslog, Selbstpruefung 22/22 PASS).
Entscheidungshintergrund: [ADR-014](docs/decisions/ADR-014-task-aktionen-ueber-run-hidden-wrapper.md).

## Qualitätsgate

`npm run verify` ist das kanonische Gate und deckt alles ab: Lint (Biome),
Typecheck (`tsc --noEmit`), PowerShell-Syntaxcheck (62+ Skripte),
Konventions-Wächter (`scripts/check-conventions.ps1`: Claude-Bann +
Mirror-Sync-Header), Repo-Tests (nextdns-Pester + Smokes, Watchdog-DryRun),
Bun-Tests (skills-manager + memory-ingest) und die Drift-Checks für
Conventional Commits + CHANGELOG. Erzwungen durch `scripts/hooks/pre-push`
(`core.hooksPath=scripts/hooks` ist gesetzt). Beratende Zusatzstufe im
Hook: der agenttrace-Session-Audit (`npm run audit:sessions`) erzeugt
einen Health-Bericht der lokalen AI-Coding-Sessions und warnt bei
kritischen Anomalien - ohne den Push je zu blockieren.

Zusaetzlich (Windows, manuell): `pwsh -File node-watchdog/run-tests.ps1`
(Watchdog-Integrationstests, 21/21 nach ADR-001-Closure) und
`pwsh -File scripts/mirror-sync.ps1 -Check` (Mirror-Integritaet, auch im
Verify-Gate enthalten).
