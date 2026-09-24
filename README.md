# tools-entwicklung

Windows Scheduled Tasks & Watchdogs as code.

- `plan.md` – genehmigter Masterplan (Slices T1–T7), verbindlich für die Implementierungs-Sitzung
- `node-watchdog/` – globaler Node/Electron/esbuild-Watchdog (DryRun-Default, Whitelist, Baum-Kill)
- `task/` – exportierte Task-XMLs aller eigenen Scheduled Tasks

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

## Qualitätsgate

`npm run lint` (Biome) · `npm run syntaxcheck` (PS-Parser) · `npm test`
erzwungen durch `scripts/hooks/pre-push` (aktivieren: `git config core.hooksPath scripts/hooks`).
