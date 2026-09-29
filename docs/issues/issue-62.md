# #62: Skript-Inventar - Notwendigkeit/Qualitaet/Nutzfaktor + ruflo/node-monitor-Reststellen (Slice 4 Struktur-Plan)

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#62](https://github.com/MaxHambi/freebuff-dev-setup/issues/62).
> Label: `ready-for-agent`. Status: in Arbeit (Slice 4 des Struktur-Plans
> `docs/plan-2026-09-29-struktur-ordnung.md`).

## Inventory-Report (Scope: scripts/, node-watchdog/, routed-watch/, maintenance/)

### scripts/ (7 Dateien + hooks/)

| Datei | Notwendigkeit (Beleg) | Qualitaet | Nutzfaktor | Empfehlung |
|---|---|---|---|---|
| `deploy.ps1` | Deploy-Pipeline (`npm run deploy`), spiegelt 4 Ordner nach `.tools` | Syntaxcheck OK, Merge-/Log-Logik sauber | jede Runtime-Aenderung | **behalten** — Code bereits ohne Alt-Ordner (node-monitor/ruflo fehlen) |
| `install-task.ps1` | `npm run install-task`, Task-Map 5 Tasks, AtLogon per-user (#32-Erkenntnis) | OK | Registrierung/Re-Registrierung | **behalten** — taskMap enthaelt keine Alt-Tasks |
| `export-tasks.ps1` | `npm run export-tasks`, XML-Backups je Task | OK | nach jeder Registrierung | **behalten** — taskNames enthaelt keine Alt-Tasks |
| `test.ps1` | `npm run test:repo`, Teil des Verify-Gates | OK | jeder Commit/Push | **behalten** |
| `syntaxcheck.ps1` | `npm run syntaxcheck`, Teil des Verify-Gates | OK | jeder Commit/Push | **behalten** |
| `skill-history-log.ps1` | nur manuell + geplanter Hook | OK, -FromHookJson vorhanden | **niedrig** — Hook NICHT registriert (`.claude/settings.json` existiert nicht; README-Zeile „aktiv" ist ein Ghost-Claim) | **behalten**, Hook-Registrierung als bewusst-offen dokumentieren (Operator-Entscheid) |
| `hooks/pre-push` | `core.hooksPath=scripts/hooks` | laeuft bei jedem Push (verify-Gate) | jeder Push | **behalten** |

### node-watchdog/

| Datei | Empfehlung |
|---|---|
| `node-watchdog.ps1` | **behalten** — Kernstueck (Slice 3: 2 Fixes, Harness 21/21 PASS) |
| `run-tests.ps1` | **behalten** — jetzt ohne Known-Fails, mit `-RcaDump` |
| `whitelist.txt` | **behalten**, `node-monitor`-Zeile entfernen (Alt-Rest, gehoert nicht zu diesem Projekt) |
| `node-watchdog.log` | **behalten (lokal)** — Runtime-Artefakt, gitignored (`.gitignore: node-watchdog/*.log`) |

### routed-watch/ + maintenance/

| Datei | Empfehlung |
|---|---|
| `watch-wrapper.ps1` | **behalten** — Task RoutedWatch laeuft darauf (XML-Beleg) |
| `npm-cleanup.ps1` / `tooling-cleanup.ps1` | **behalten** — Tasks NpmCleanup/ToolingCleanup (XML-Beleg) |
| `run-hidden.vbs` | **loeschen** — von KEINEM Task-XML und KEINEM Skript referenziert (Tasks laufen direkt `powershell -WindowStyle Hidden`); nur plan.md-Prosa nennt es historisch |

### Reststellen ruflo-policy-rotate / node-monitor

- README deploy-/install-task-/export-tasks-Zeilen: Alt-Referenzen streichen (Code selbst ist schon sauber — bewiesen).
- `node-watchdog/whitelist.txt`: `node-monitor`-Zeile entfernen.
- `task/Ruflo-PolicyLedger-Rotate-workspace.xml`: bleibt als Archiv (plan.md bindend), bekommt Archiv-Kommentar-Header (XML-Kommentar nach Deklaration; GUI-Import toleriert Kommentare).
- Mirror/plan.md/CHANGELOG-Historie: bleiben (append-only).

## Umsetzungsstand

- [x] README-Tabellen bereinigt (deploy/install-task/export-tasks ohne Alt-Referenzen; skill-history-Hook als nicht registriert; pre-push-Beschreibung auf `npm run verify` korrigiert)
- [x] `whitelist.txt`: `node-monitor` entfernt
- [x] Ruflo-XML: Archiv-Kommentar eingefuegt (UTF-16-sicher)
- [x] `maintenance/run-hidden.vbs` geloescht (null Referenzen bewiesen)
