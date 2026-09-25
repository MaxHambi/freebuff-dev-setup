# tools-entwicklung

Windows Scheduled Tasks & Watchdogs as code - plus Skills-Manager fuer die
persoenliche Agent-Skills-Bibliothek.

| Bereich | Inhalt | Doku |
|---------|--------|------|
| `plan.md` | Genehmigter Masterplan (Slices T1–T7), verbindlich fuer die Implementierung; T1 erfuellt (ADR-001 offen) | - |
| `node-watchdog/` | Globaler Node/Electron/esbuild-Watchdog (DryRun-Default, Whitelist, Baum-Kill, Log-Rotation) | ADR-001 |
| `skills-manager/` | Analyse-CLI fuer `~/.agents/skills` (Slice 1 gemerged; TUI-Slices via ADR-006 verworfen) | `skills-manager/docs/` |
| `skills/` | Eigene Agent Skills (Meta-Skill `using-skills` mit Gate + Router + Hooks) | unten, Abschnitt Skills-Verzeichnis |
| `task/` | Exportierte Task-XMLs aller eigenen Scheduled Tasks (GUI-Backup) | unten, Wiederherstellung |
| `docs/decisions/` | Architekturentscheidungen als ADRs (ADR-001 bis ADR-005) | `docs/index.md` |

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
## Skills-Verzeichnis (`skills/`)

Das Repo versioniert eigene Agent Skills unter `skills/`; Deploy-Ziel ist
`%USERPROFILE%\.agents\skills\<name>\` (Registrierung im routed-Index via
`skills-sync.ps1` oder MCP `scan_skills`).

### skills/using-skills — Meta-Skill (Gate + Router)

Vereint das 1%-Skill-Gate (using-superpowers), den Phasen-Baum (using-agent-skills)
und den Interview-Funnel (skill-router); Discovery-Fallback ueber routed MCP.

| Artefakt | Zweck |
|---|---|
| `SKILL.md` | Gate → Router → Interview → routed-Discovery → Operating Behaviors; i18n-Regeln (deutsch-englische Trigger-Description) |
| `references/routing-reference.md` | Vollstaendiger Phasen-Baum, Kategorie-Routing, Interview-Funnel, Lifecycle |
| `references/routed-mcp.md` | MCP-Tool-Signaturen, Standard-Workflow, CLI-Fallback, Fehlersignaturen |
| `hooks/route-gate.ps1` | Gate-Enforcement per routed CLI. Exit `0` = kein Skill noetig, `1` = Skill-Treffer einladen, `2` = routed nicht erreichbar |
| `hooks/skills-sync.ps1` | Snapshot-Diff ueber die Skills-Ordner (`.gemini/config/plugins`, `.agents/skills`, `.claude/skills`) + Registrierung via `routed scan`. Switches: `-Force`, `-HashContent` (SHA-256 statt Zeitstempel+Groesse) |

Hooks ausfuehren:

```powershell
pwsh -File skills/using-skills/hooks/route-gate.ps1 -Prompt "<task>"
pwsh -File skills/using-skills/hooks/skills-sync.ps1
```

State des Syncs: `%APPDATA%\routed\skills-sync.state.json` (nur nach
erfolgreichem Scan geschrieben). Aenderungen an Skills immer am Deploy-Ziel
und im Repo pflegen, danach Sync laufen lassen.

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
  (`routed scan_skills` → Stand: >2800 Skills).
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
| `git-pr-workflows-git-workflow`, `git-pr-workflows-pr-enhance` | installiert | Conventional-Commits-, Branch- und PR-Pipeline |
| `changelog-automation`, `documentation-and-adrs`, `documentation-generation-doc-generate` | installiert | Changelog (Keep a Changelog), ADR- und Doku-Generierung |
| `interview-style-doc-building`, `brain-to-docs`, `code-documentation-doc-generate` | installiert | Interviewbasierte Doku-Erstellung |

Deploy-Ziel eigener Skills: `%USERPROFILE%.agentsskills<name>`, danach
`skills-sync.ps1` oder MCP `scan_skills` (siehe ADR-002: `scan_skills` ist
der massgebliche Indexierungsweg).

## Deploy & Task-Registrierung (`scripts/`)

Die Helper bilden die Pipeline Repo → Runtime → Task-Registrierung → XML-Backup.
Reihenfolge: erst `deploy`, dann `install-task`, dann `export-tasks`.

| Helper | Zweck |
|---|---|
| `scripts/deploy.ps1` | Spiegelt die Task-Ordner (`node-watchdog`, `node-monitor`, `maintenance`, `routed-watch`, `ruflo-policy-rotate`) nach `%USERPROFILE%\.tools`. Merge-Logik: existierende Dateien bleiben stehen (`KEEP`), Überschreiben nur mit `-Force` (`COPY`). Noch nicht vorhandene Ordner werden übersprungen (`SKIP`). |
| `scripts/install-task.ps1` | Registriert Scheduled Tasks auf die Runtime-Pfade. Task-Auswahl per `-Task` (bekannt: `Node Watchdog`, `NodeProcessMonitor`, `NpmCleanup`, `ToolingCleanup`, `RoutedWatch`). Prüft die Skript-Existenz im Runtime-Ziel und zeigt die fertige Task-Aktion; Trigger/Intervalle werden je Slice (T2–T6) ergänzt. |
| `scripts/export-tasks.ps1` | Sichert registrierte Tasks als XML nach `task\<Name>.xml` (`schtasks /query /tn <name> /xml`), inkl. `Ruflo-PolicyLedger-Rotate-workspace`. Nicht registrierte Tasks → `SKIP`. Diese XMLs sind das Backup für die GUI-Wiederherstellung (siehe oben). |

Beispielaufrufe:

```powershell
# 1) Runtime-Kopien nach %USERPROFILE%\.tools spiegeln (bestehende Dateien bleiben erhalten)
pwsh -File scripts/deploy.ps1

# Repo-Stand durchsetzen (alle Zieldateien ueberschreiben)
pwsh -File scripts/deploy.ps1 -Force

# 2) Task registrieren - Aktion zeigt auf den Runtime-Pfad, nicht ins Repo
pwsh -File scripts/install-task.ps1 -Task "Node Watchdog"

# 3) Task-Definition als XML sichern (Backup fuer GUI-Import)
pwsh -File scripts/export-tasks.ps1
```

Konventionen: Runtime-Pfade zeigen immer auf `%USERPROFILE%\.tools`, nie ins Repo.
Die exportierten XMLs enthalten absolute Pfade dieses Rechners und dienen nur als
Backup - nie als Installationsquelle. Destruktive Schritte (Überschreiben mit
`-Force`, Task-Neuregistrierung) erst nach einem Report-/DryRun-Lauf ausführen.

## Qualitätsgate

`npm run lint` (Biome) · `npm run syntaxcheck` (PS-Parser) · `npm test`
erzwungen durch `scripts/hooks/pre-push` (aktivieren: `git config core.hooksPath scripts/hooks`).
