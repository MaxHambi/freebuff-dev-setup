# routed-MCP-Referenz

routed ist der lokale Skill-Routing-Server: indexiert Skills aller Tool-Hosts
in eine SQLite-DB und matched Prompts per BM25 + Embeddings ohne LLM-Kontext.

## Server

- Konfiguration: `.cline/mcp_settings.json` -> Server `routed`
  (command `routed`, args `["mcp"]`).
- Binary: `%LOCALAPPDATA%\Programs\Routed\bin\routed.cmd` (Version:
  `routed --version`).
- Index: `%APPDATA%\routed\index.db` (+ `-wal`/`-shm`).

## MCP-Tools

| Tool | Parameter | Zweck |
|---|---|---|
| `route_skill` | `prompt` (Pflicht), `topK` 1-10 (Default 3), `host`, `explain` | Prompt -> bester Skill |
| `get_skill` | `id` (Skill-ID oder Name, case-insensitive) | Volltext-SKILL.md + Manifest laden |
| `list_skills` | `filter` (Substring), `host` | Index durchsuchen/zaehlen |
| `scan_skills` | `workspace` (optional) | Index von Disk neu aufbauen |
| `record_feedback` | `query`, `chosenSkillId` | Korrektur zurueckspielen, Routing lernen |

## Standard-Workflow

```
route_skill(prompt=<Task>, topK=3)
  -> isNoSkill=true?        -> ohne Skill weiterarbeiten
  -> bester Treffer         -> get_skill(id)
  -> Announce "Using [skill] to [purpose]" -> SKILL.md folgen
  -> User korrigiert Route? -> record_feedback(query, chosenSkillId)
```

Regeln:

- Nach dem Installieren oder Bearbeiten von Skills immer `scan_skills`
  ausfuehren, sonst liefert der Index alte Fassungen aus. Nur `scan_skills`
  (upsert-only, kein Prune) — `hooks/skills-sync.ps1` ist stillgelegt
  (Issue #15/C1: `routed scan` pruned global, siehe SKILL.md),
- Bei Aenderungen an Skill-Dateien an ALLEN Ablageorten pflegen (canonical
  `.gemini\config\plugins\...` + Kopie `.agents\skills\...`), dann scannen.
- Mehrere Treffer mit aehnlichem Score: SKILL.md der Top-2 lesen und die
  Prämisse pruefen, statt blind dem ersten zu folgen.
- `explain=true` liefert Score-Signale (exact/BM25/semantic) - nützlich bei
  scheinbar falschen Treffern.

## CLI-Fallback (kein MCP verfuegbar)

```bash
routed route --json "<prompt>"        # JSON mit selectedSkills + path
routed --version
```

**ACHTUNG (C4, live passiert 2026-09-29):** `routed scan --help` ist KEIN
Help-Aufruf — die CLI startet den echten Scan (ohne Help-Guard) und pruned
dabei den Index global (damals 2867 -> 393 Rows). **Niemals `routed scan`
auch nicht mit `--help` anfassen**; Hilfe nur über `routed --version` oder
den Quelltext unter `%LOCALAPPDATA%\Programs\Routed\packages\`. Registrierung
immer via MCP `scan_skills` (upsert-only, siehe oben).

- `selectedSkills[].skill.path` zeigt auf die `SKILL.md` -> direkt lesen.
- Wrapper-Script: `hooks/route-gate.ps1 -Prompt "<task>"` (Exit 1 = Skill
  einladen, Exit 0 = kein Skill noetig, Exit 2 = routed nicht erreichbar).

## Fehlersignaturen

| Symptom | Ursache | Loesung |
|---|---|---|
| `routed: command not found` (bash) | PATH nur in Windows-Shells | via pwsh/cmd aufrufen oder `where.exe routed` |
| Skills fehlen im Index | neu installiert, nicht gescannt | `scan_skills` ausfuehren |
| Veralteter Skill-Inhalt | Datei geaendert, Hash stale | `scan_skills`, dann `get_skill` |
| Doppelt vergebene Namen ueber Hosts | gleicher Skill in mehreren Tools | gewuenschten `host`-Filter setzen |
| Index-Zahl springt stark nach einem CLI-Aufruf | `routed scan` hat geprunt (globaler `removeMissingSkills`) | sofort MCP `scan_skills` laufen lassen (upsert-only, repariert die erkannten Roots); Details #15, `skills-sync.ps1` bleibt stillgelegt |
| User-Bibliothek (`~/.agents/skills`) fehlt im Index | Detector-Kanntnis + Container-Recursion-Stopp (routed v1.6.95) | `ROUTED_CONFIG_PATH` ist gesetzt (User-Level); volle Registrierung erst nach routed-Fix (upstream bshea-1/Routed#2) + Host-Neustart via `scan_skills` |
| Niedrige Confidence bei klarem Fall | Begriffe fehlen in Beschreibung | Skill-description schaerfen, `record_feedback` |
