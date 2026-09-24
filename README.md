# tools-entwicklung

Windows Scheduled Tasks & Watchdogs as code.

- `plan.md` – genehmigter Masterplan (Slices T1–T7), verbindlich für die Implementierungs-Sitzung
- `node-watchdog/` – globaler Node/Electron/esbuild-Watchdog (DryRun-Default, Whitelist, Baum-Kill)
- `task/` – exportierte Task-XMLs aller eigenen Scheduled Tasks

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
