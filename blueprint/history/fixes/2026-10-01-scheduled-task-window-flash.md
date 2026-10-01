# Fix: Scheduled-Task-Fenster-Flash (Node Watchdog + Rest-Migration)

> Archiviert am 2026-10-01 via /complete. Nachfolge-Plan:
> `docs/plan-2026-10-01-fenster-flash-migration.md` (Slices 0-7), Beweiskette:
> `audit/2026-10-01-fenster-flash/`. PRs: #66 (Fix), #67 (CI-Lockfile-Fix).

**Bug:** Alle 10 Minuten blitzte ca. 0,5 s lang ein PowerShell-Fenster auf
(wahrgenommen als "rund alle 15 Minuten"). Nach dem Watchdog-Fix folgte der
zweite Nachweis-Flash gegen 12:34: MemoryIngest (4-h-Raster) lief um 12:30:01
noch mit direktem powershell.exe.

**Root-Cause:** Task-Aktionen starteten direkt `powershell.exe -WindowStyle
Hidden`; Windows erzeugt das conhost-Fenster einer Konsolenanwendung sichtbar,
bevor PowerShell den Schalter verarbeitet. Das flash-freie `wscript.exe
run-hidden.vbs`-Muster (SW_HIDE ab Prozessstart) war bei der Task-Migration
verloren gegangen.

**Fix:**
- `maintenance/run-hidden.vbs` ins Repo, erweitert um Argument-Weiterreichung
  1..n (alter Wrapper haette das bindende `-Apply` verschluckt; Smoketest
  `apply=True`)
- `scripts/install-task.ps1` erzeugt fuer alle Tasks Wrapper-Aktionen
  (Standardpfad + AtLogon-Zweig)
- Live-Migration aller fuenf eigenen Tasks per XML-Round-Trip
  (Trigger/Principal/Settings byte-identisch): Node Watchdog, MemoryIngest,
  NpmCleanup, ToolingCleanup, RoutedWatch (vorher Stop, danach Start)
- TaskScheduler-Historie aktiviert (wevtutil, Admin) - Vorfaelle ab
  2026-10-01 per Event-Log beweisbar
- CI-Nebenbefund: PR #33 hatte bun.lock nicht mit dem Biome-Bump synchronisiert
  -> PR #67 fixt den frozen-lockfile-CI-Bruch

**Done-when (alle mit Beweis):**
- [x] Beweiskette P1-P10 + Entscheidungslog E1-E6 im Audit
- [x] Wrapper-Smoketest apply=True; Watchdog-Parameter [switch]$Apply (Zeile 25)
- [x] 5/5 Live-Tasks mit Exec=wscript.exe + run-hidden.vbs-Arguments (Live-Check + Selbstpruefung)
- [x] Repo-Backups task/*.xml aktualisiert (6/6 auf wscript)
- [x] npm run verify gruen (41/41 Bun-Tests, tsc, Biome, Syntaxcheck, Drift-Checks)
- [x] Erster regelmaessiger Lauf nach dem Fix: 02:40:01 Start Mode=APPLY, Result 0x0
- [x] Selbstpruefung 22/22 PASS (inkl. Historie-Events fließen)
- [x] CI auf PR #67 voll gruen (6/6 Checks)

**Rollback:** VORHER-XMLs in `audit/2026-10-01-fenster-flash/02-beweise/`
(bzw. /migration/) je Task per `schtasks /create /xml ... /f` zurueckspielen.

**Nicht angefasst:** Watchdog-Logik/Intervalle, Trigger-/Settings-Bloecke,
Drittanbieter-Tasks (cua-driver-serve, Hermes_Gateway, MiTeC, OneDrive,
PowerToys), deskreen-Repo.
