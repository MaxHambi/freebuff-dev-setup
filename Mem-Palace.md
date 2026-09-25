# MemPalace — Meine Konfiguration & Bedienung

> Private Referenz (nur für Max). Stand: 25.09.2026, MemPalace **3.10.0**.
> Setup ausgeführt gemäß `/mempalace`-Skill; LLM-Verfeinerung siehe
> [`D:\mempalace\LLM-VERFEINERUNG.md`](file:///D:/mempalace/LLM-VERFEINERUNG.md).

---

## 1. Wie MemPalace bei mir konfiguriert ist

### Kern-Setup

| Baustein | Wert |
|---|---|
| **Installation** | `uv tool install mempalace` → 3.10.0, Executables in `C:\Users\Max Hambi\.local\bin\` (`mempalace`, `mempalace-mcp`, `mempalace-light-mcp`) |
| **Palast-Daten** | `D:\mempalace\palace` ← **bewusst auf D:** (Speicherplatz), gesetzt über `palace_path` in `~/.config/mempalace/config.json` |
| **Identity-Datei** | `C:\Users\Max Hambi\.memorypalace\config.json` (palace_id/palace_key — nur Identität, keine Daten) |
| **XDG-Config** | `~/.config/mempalace/config.json` → `{ "palace_path": "D:\\mempalace\\palace" }`; hier landen auch `entity_languages` und Update-Einstellungen |
| **Topologie** | Shared-brain **Hub-Vorbereitung** (dieser Rechner besitzt den Palast); `mempalace serve` läuft aktuell **nicht** — erst starten, wenn ein Client aus dem Netz kommt |
| **Agent-Identity** | `maxhambi:freebuff:freebuff-dev-setup` (Freebuff) und `maxhambi:claude:*` (Claude Code, unveraendert) — host:harness:project, lowercase |
| **Corpus** | `D:\freebuff-dev-setup` — 100 Dateien, **707 Drawers** (Wing `freebuff_dev_setup`, frisch initialisiert 25.09.2026 nach dem /mempalace-Skill) |
| **Update-Checks** | Wöchentlich, Installer `uv-tool` registriert (`mempalace update configure --enable --installer uv-tool`) |

### Struktur im Palast (Wing `freebuff_dev_setup`)

| Room | Drawers | Quelle |
|---|---|---|
| skills | 538 | `skills/` (Spiegel der Skill-Bibliothek) |
| documentation | 72 | `docs/` |
| blueprint | 72 | `blueprint/` |
| task | 14 | `task/` |
| general | 6 | Rest |
| scripts | 4 | `scripts/` |
| node_watchdog | 1 | `node-watchdog/` |

> **Fresh rebuild 25.09.2026 (/mempalace-Skill):** Der fruehere Palast (Wings `tools_entwicklung` + `freebuff_dev_setup` gemischt, 1378 Drawers) wurde gesichert nach `D:\mempalace\palace-backup-20260925` und komplett neu initialisiert. Der alte Wing `tools_entwicklung` existiert nicht mehr. Backup-Loeschung ist eine spaetere manuelle Entscheidung.
Die Room-Zuordnung steuert **`mempalace.yaml` im Repo-Root** (Verzeichnis →
Room + Keywords). Dort kann ich Rooms ergänzen/ändern (siehe §4).

### MCP-Anbindungen

| Harness | Registrierung | Status |
|---|---|---|
| **Claude Code** | `claude mcp add mempalace -- mempalace-mcp` (project-scoped `D:\tools-entwicklung`, Eintrag in `~/.claude.json`) | ✔ live verifiziert (✔ Connected) |
| **Freebuff** | `D:\freebuff-dev-setup\.mcp.json` → `"mempalace": { "command": "C:\\Users\\Max Hambi\\.local\\bin\\mempalace-mcp.exe" }` | ⏳ Datei angelegt; **Freebuff-Restart + Consent** nötig, dann Tool-Liste prüfen |
| **Rules-Block** | `~/.claude/CLAUDE.md` → `<!-- mempalace-shared-brain -->`-Block (88 Zeilen, gerendert mit `mempalace rules --host maxhambi --harness claude --project tools-entwicklung`) | ✔ installiert |
| **Rules-Block (Freebuff)** | `AGENTS.md` (Projekt-Root) → `<!-- mempalace-shared-brain -->`-Block (88 Zeilen, gerendert mit `mempalace rules --host maxhambi --harness freebuff --project freebuff-dev-setup`) | ✔ installiert |

> Freebuff-Nebenbefund: Die verwalteten Server (rayrun, synapse, routed,
> claimidx) kommen aus `managed-mcp.json` (App-intern); eigene Server laufen
> über die projekt-lokale `.mcp.json`. Approval-State liegt in
> `~/.freebuff/mcp.json` (Hash-Keys, `configKey`, `enabled`).

> **.claude-Ausschluss (User-Constraint, Issue #24):** Claude-Code-Harness-Verweise — `CLAUDE.md`-Symlink, `~/.claude.json`-Project-Key, Rules-Block-Identity `maxhambi:claude:*` — bleiben bis zur App-Migration bewusst auf dem alten Namen und wurden bei der Umbenennung nicht angefasst.

### Watcher-Modus

**Declared-idle** — kein Hintergrund-Watcher. Inbox wird bei Kollaboration
bzw. vor langen Tasks gesweept (`mempalace logstream list` bzw.
`mempalace_event_list` mit Cursor). `logstream watch` nur bei explizitem
Hören-Wollen/Delegation bewaffnen. Smoke-Events nur mit meiner Freigabe
(logstream ist **immutable**).

---

## 2. Verwendung im Alltag

### Suchen (der Haupt-Use-Case)

```bash
mempalace search "skill-designer eval ranking"   # Volltext über alle Drawers
mempalace hallways                                # Entity-Graph: wer/was hängt zusammen
mempalace wake-up                                 # L0+L1-Kontext (~600–900 Token)
```

In Claude Code/Freebuff (nach Consent): die `mempalace_*`-MCP-Tools nutzen —
vor Antworten über frühere Arbeit **immer erst suchen** (Recall-Protokoll),
Treffer wörtlich zitieren, nicht paraphrasieren. Für reine Rückfragen ist der
Skill **`mempalace-recall`** zuständig (search-before-answer).

### Wissen einpflegen

- **Automatisch:** `mempalace mine D:/freebuff-dev-setup` filed Dateien aus
  dem Repo (idempotent — bereits gefilte werden übersprungen).
  Tandem-Miner: `mempalace sweep` holt nach, was der Primary verpasst hat.
- **Manuell/agentisch:** `mempalace_add_drawer` (MCP) für Entscheidungen und
  Fakten. Keine Secrets/tokens filed!
- **Aufräumen:** `mempalace sync` löscht Drawers, deren Quelldateien
  gitignored/gelöscht/gezogen sind.

### Status & Fehlersuche

```bash
mempalace status          # Rooms/Drawers-Zähler, Palast-Gesundheit
mempalace repair-status   # sqlite vs. HNSW-Index (read-only)
mempalace update check    # Version vs. PyPI (kontaktiert PyPI, sendet nichts)
```

---

## 3. Optimierung

1. **LLM-Verfeinerung (größter Hebel):** Init lief bisher heuristisch
   (`--no-llm`). Mit Ollama/LM Studio: Entity-Verfeinerung (Pfad A) und
   Closet-Regenerierung (Pfad B) nachziehen → präzisere Hallways und
   topic-dichte Suchindizes. **Komplett-Anleitung:**
   [`D:\mempalace\LLM-VERFEINERUNG.md`](file:///D:/mempalace/LLM-VERFEINERUNG.md)
2. **Mehrsprachigkeit:** Entity-Erkennung auf `en,de` stellen (Feld
   `entity_languages` in `~/.config/mempalace/config.json` oder
   `MEMPALACE_ENTITY_LANGUAGES=en,de`) — mein Corpus ist gemischt DE/EN.
3. **Kompression:** `mempalace compress` erzeugt AAAK-Dialect-Closets
   (~30x Reduktion) für große Rooms — erst sinnvoll, wenn der Palast
   wächst; Standard erstmal nicht nötig.
4. **Suche-Disziplin:** exakte Begriffe (Skill-Namen, Dateinamen, Person)
   schlagen Prosa-Fragen; bei nichts gefundenem: sagen, dass der Palast
   nichts hat — nicht raten.
5. **Transcripts einbeziehen:** Claude-Code-Session-Verläufe aus
   `~/.claude/projects` können mit `mempalace split` (vorher!) + `mine
   --mode convos` aufgenommen werden — macht Agent-Historien durchsuchbar.

---

## 4. Erweiterbarkeit

- **Neues Corpus (z. B. zweites Repo):** eigener Wing →
  `mempalace init --yes --auto-mine --wing <name> "D:/anderes-repo"` bzw.
  `mine --wing <name>`. Ein Palast trägt beliebig viele Wings.
- **Rooms anpassen:** `mempalace.yaml` im Repo-Root editieren (name,
  description, keywords) und neu minen — Room-Zuordnung folgt den Keywords.
- **Fleet/Hub aktivieren:** `mempalace serve` (Bearer-Token, Port 8765,
  TLS-Optionen); Client-Anbindung via HTTP-MCP-Transport + Token. Token
  **niemals** in Instructions/Drawers/Events ablegen. Regeln-Block für
  andere Harnesses: `mempalace rules --host <host> --harness <harness>
  --project <projekt>` → in deren dauerhafte Instructions (z. B.
  `~/.codex/AGENTS.md`, `~/.gemini/config/GEMINI.md`).
- **Leichtgewichtige Variante:** `mempalace-light-mcp` (3 konsolidierte
  Tools, ~92 % weniger Schema-Tokens) — sinnvoll, wenn 47 Tools zu viel
  Kontext fressen; dann Rules mit `--mcp light` neu rendern.
- **Backend:** Standard Chroma/SQLite lokal. Remote-Backends (Qdrant,
  Milvus) via `MEMPALACE_QDRANT_URL` / `MEMPALACE_MILVUS_URI` (Env) — nur
  bei echtem Bedarf.

---

## 5. FAQ (nur für mich)

**Wo liegen eigentlich meine Daten?**
Palast: `D:\mempalace\palace` (Chroma/SQLite). Identity:
`~/.memorypalace/config.json`. Settings: `~/.config/mempalace/config.json`.
Nichts im Cloud, keine API-Keys nötig.

**Warum hängt `mempalace init` manchmal?**
Ohne `--auto-mine` fragt es interaktiv nach dem Post-Init-Mine — in
nicht-TTY-Kontexten wartet es ewig. Immer `--yes --auto-mine` mitgeben.

**`--palace`-Flag oder Config?**
Config (einmal gesetzt) gilt überall inkl. MCP-Server. Nur der direkte
Modul-Aufruf `python -m mempalace.closet_llm` braucht `--palace` explizit
(sein Default wäre `~/.mempalace/palace` — falsch).

**Was ist der Unterschied Drawer / Closet / Hallway?**
Drawer = eine gefilte Informationseinheit (aus Datei/Transkript). Closet =
Suchindex-Eintrag pro Quelldatei (Topics/Quotes/Summary — regex- oder
LLM-generiert). Hallway = Verknüpfung zwischen Entitäten (Personen,
Projekte) über Drawers hinweg.

**Muss ich beim Minen was beachten?**
Vor Convos-Mining `mempalace split` (Mega-Transcripte splitten). Subagent-
Transcripts sind bewusst ausgeschlossen (`--include-subagents` zum
Einschließen). Windows-ONNX-Fall: `--max-chunks-per-file` senken.

**Kostet die Suche was / geht was nach draußen?**
Nein/Nein. Suche & Mining sind lokal, kein API-Key. Nur die opt-in
LLM-Verfeinerung sendet Inhalte — bei Cloud-Endpunkten (siehe
LLM-VERFEINERUNG.md, Abschnitt Datenschutz).

**Freebuff sieht mempalace nicht — was fehlt?**
Freebuff-Restart + Consent-Prompt für den Server aus `.mcp.json`
bestätigen; danach in der Session `search_mcp_tools` mit „mempalace"
prüfen. Die `.mcp.json` liegt untracked im Repo — beim nächsten Commit
entscheiden: committen (Team) oder in `.gitignore`.

**Wie aktualisiere ich MemPalace?**
`uv tool upgrade mempalace`, danach ggf. `mempalace migrate` (Chroma-
Versionssprünge) und `mempalace status` gegenprüfen. Restart-Flag beachten
(`update check` → `restart_required_after_upgrade`).

**Neue große Entscheidung erarbeitet — wie file ich sie?**
Kurz über MCP `mempalace_add_drawer` (Entscheidung + Begründung, Quellen-
Pfad erwähnen) oder sie im Repo als ADR/Doc ablegen und `mempalace mine`
laufen lassen — beide Wege enden durchsuchbar im Palast.

**Wann brauche ich `mempalace-task` statt dem hier?**
Nur bei aktiver Delegation über den Logstream (Tasks verteilen/einkassieren)
— dann auf den gleichnamigen Skill wechseln.
