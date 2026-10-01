# Current Feature

> **Generated file.** Holds the one feature, fix, or rollback being built right now. Run
> `/feature <number-or-name>` to spec a build-plan feature, or `/fix "<bug>"` for
> an ad-hoc fix. Use `/rollback <completed-feature>` to plan a safe reversal.
> Build one thing at a time; `/complete` archives it under
> `blueprint/history/` and resets this file.

## Fix: Scheduled-Task-Fenster-Flash (Node Watchdog, 2026-10-01)

**Bug:** Alle 10 Minuten blitzt ca. 0,5 s lang ein PowerShell-Fenster auf
(wahrgenommen als "rund alle 15 Minuten"). Ursache: Task "Node Watchdog"
startete direkt `powershell.exe -WindowStyle Hidden`; Windows erzeugt das
conhost-Fenster einer Konsolenanwendung, bevor PowerShell den Schalter
verarbeitet. Das flash-freie `wscript.exe run-hidden.vbs`-Muster war bei der
Migration durch direkte Aufrufe ersetzt worden. Vollstaendige Beweiskette:
`audit/2026-10-01-fenster-flash/`.

**Done-when:**

- [x] Beweis dokumentiert (Trigger-XML, Log-Raster, Mechanismus, Ausschluesse)
- [x] `maintenance/run-hidden.vbs` im Repo, reicht alle Argumente weiter (Fix: vorher nur Arguments(0), `-Apply` waere verloren gegangen)
- [x] `scripts/install-task.ps1` erzeugt fuer alle Tasks Wrapper-Aktionen (Standardpfad + AtLogon-Zweig)
- [x] Wrapper-Smoketest: `apply=True` (Switch-Bindung bewiesen)
- [x] Live-Task "Node Watchdog" per XML-Round-Trip umgestellt (Trigger/Principal/Settings byte-identisch), VORHER/NACHHER-XML im Audit
- [x] `task/Node Watchdog.xml` aktualisiert
- [x] `npm run verify` gruen (41/41 Bun-Tests, tsc, Biome, Syntaxcheck, Konventionen, Drift-Checks)
- [x] Erster regelmaessiger Lauf nach dem Patch: `02:40:01 Start: Mode=APPLY` (Flag via Wrapper durchgereicht) + `LastTaskResult 0x0`

**Nicht Teil des Fixes:** Live-Umstellung der vier uebrigen Tasks (nur
Repo-Muster, Ausrollen per `install-task.ps1 -Register` auf Zuruf);
TaskScheduler-Historie aktivieren (auf Zuruf).

**Rollback:** `schtasks /create /tn "Node Watchdog" /xml audit/2026-10-01-fenster-flash/02-beweise/node-watchdog-VORHER.xml /f`
