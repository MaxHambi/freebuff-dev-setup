# Protokoll der Untersuchung (chronologisch)

Jeder Schritt mit Befehl (gekuerzt auf das Wesentliche), Ausgabeauszug, Zweck
und Schluss. Alle Befehle liefen am 2026-10-01 zwischen ca. 01:45 und 02:30
(Systemzeit, Windows). Vollstaendige Rohtexte der Ausgaben liegen teils in
`02-beweise/`, teils sind sie hier inhaltstreu als Auszug dokumentiert.

## P1: Trigger und Aktionen aller Kandidaten-Tasks abfragen

Befehl: `schtasks /query /tn <name> /xml` fuer NpmCleanup, ToolingCleanup,
RoutedWatch, Ruflo-PolicyLedger-Rotate-workspace, NodeProcessMonitor,
Node Watchdog; gefiltert nach Interval/Execution/Arguments/StartBoundary.

Auszug (relevante Zeilen):
- NpmCleanup: StartBoundary 03:00, DaysInterval 1, powershell.exe direkt
- ToolingCleanup: StartBoundary 04:00, DaysInterval 1, powershell.exe direkt
- RoutedWatch: Interval PT1M, powershell.exe direkt
- Ruflo-PolicyLedger-Rotate-workspace: NOT REGISTERED
- NodeProcessMonitor: NOT REGISTERED
- Node Watchdog: StartBoundary 00:00, **Interval PT10M**, powershell.exe
  direkt, Arguments enthalten `-File "...node-watchdog.ps1" -Apply`

Zweck/Schluss: Erster Verdacht faellt auf den 10-Minuten-Task. RoutedWatch
(1-Minuten-Trigger, aber Logon-Kontext und laufender Wrapper-Prozess) und die
taeglichen Cleanups sind mechanisch unvereinbar mit einem ~15-Minuten-Rhythmus.

## P2: LastRun/NextRun aller Nicht-Microsoft-Tasks

Befehl: `Get-ScheduledTask | Where TaskPath -eq '\' | Get-ScheduledTaskInfo`.

Auszug:
- Node Watchdog: LastRun=01.10.2026 01:30:01, NextRun=01.10.2026 01:40:00
- RoutedWatch: LastRun=29.09.2026 11:09:35 (Logon-Trigger, kein Rhythmus)
- NpmCleanup/ToolingCleanup: naechster Lauf naechste Nacht

Schluss: LastRun/NextRun von Node Watchdog bestaetigen ein exaktes
10-Minuten-Grid. Die Wahrnehmung "rund 15 Minuten" ist damit erklaerbar:
ein Menschen-Wahrnehmungsintervall ohne Uhr, real 10 Minuten.

## P3: Trigger-/Aktionsdetail aller Nicht-Microsoft-Tasks

Befehl: `Get-ScheduledTask | Where { $_.TaskPath -notlike "\Microsoft*" }`
mit Auslesen von Repetition.Interval und Actions.

Auszug (Aktionsliste, gekuerzt):
- MemoryIngest: Interval PT4H, powershell.exe direkt
- Node Watchdog: Interval PT10M, powershell.exe direkt
- cua-driver-serve, Hermes_Gateway, MiTeC InfoBar, OneDrive, PowerToys:
  nur Logon-Trigger bzw. EXE-Aktionen ohne Konsole

Schluss: Genau zwei Kandidaten mit repetitivem Trigger und direktem
powershell.exe-Aufruf: Node Watchdog (10 Min) und MemoryIngest (4 h). Nur der
10-Minuten-Task passt zum beobachteten Rhythmus.

## P4: Watchdog-Laufhistorie im Log

Befehl: `tail -25 %USERPROFILE%\.tools\node-watchdog\node-watchdog.log`.

Auszug:
```
2026-10-01 00:40:02 Start: Mode=APPLY ...
2026-10-01 00:50:02 Start: Mode=APPLY ...
2026-10-01 01:00:03 Start: Mode=APPLY ...
2026-10-01 01:10:02 Start: Mode=APPLY ...
2026-10-01 01:20:02 Start: Mode=APPLY ...
2026-10-01 01:30:02 Start: Mode=APPLY ...
```

Schluss: Sechs Laeufe im exakten 10-Minuten-Raster. Der Start-Sekundenwert
(xx:xx:02) entspricht dem Scheduler-Feuer, nicht einem Skriptstart durch
Mensch oder fremden Prozess. Damit ist die Ausfuehrungsursache eindeutig der
Task-Scheduler und dort der Node Watchdog.

## P5: Ausschluss Microsoft-Tasks und WMI-Subscriptions

Befehl 1: `Get-ScheduledTask | Where { TaskPath -like "\Microsoft*" }` gefiltert
auf actions matching powershell/pwsh/cmd/node.
Ergebnis: nur Hotpatch Monitoring (P1D), Automatic-Device-Join (PT1H,
dsregcmd.exe, keine Konsole), Recovery-Check (dsregcmd.exe).

Befehl 2: `Get-CimInstance -Namespace root\subscription __EventConsumer` und
`CommandLineEventConsumer`.
Ergebnis: nur "SCM Event Log Consumer" (System, kein CommandLineTemplate).

Schluss: Weder Microsoft-Tasks noch WMI-Event-Consumer erzeugen
kurzintervallige sichtbare PowerShell-Fenster. WMI-Persistenz als Ursache
ausgeschlossen.

## P6: Mechanismus-Nachweis conhost-Flash

Vorbefund (Runtime-Datei gelesen): Die alte, vor der Migration bewaehrte
Vorlage `%USERPROFILE%\.tools\maintenance\run-hidden.vbs` enthaelt den
Kommentarblock zu `sh.Run cmd, 0, True` (0 = SW_HIDE ab Prozessstart).
Die Migrations-Sitzung hatte die Task-Aktionen aber auf direkte
`powershell.exe`-Aufrufe umgestellt; der Wrapper lag ungenutzt.

Schluss: PowerShell ist eine Konsolenanwendung. Startet der Task-Scheduler
sie direkt, erzeugt Windows das conhost-Fenster sichtbar und PowerShell
verarbeitet `-WindowStyle Hidden` erst danach: das Fenster blitzt ca.
300-500 ms auf und verschwindet. Ueber wscript gestartete Kinder erben
SW_HIDE ab dem ersten Befehl, es gibt keinen sichtbaren conhost.

## P7: TaskScheduler-Historie-Status

Befehl: `Get-WinEvent -LogName Microsoft-Windows-TaskScheduler/Operational`.
Ergebnis: "Operational-Log leer oder deaktiviert".

Schluss: Die Historie ist auf dieser Maschine deaktiviert, daher kann der
Beweis nicht aus Event-ID 100/129 gefuehrt werden. Die Kette P1-P6 fuehrt
den Beweis stattdessen dreifaechig: Trigger-XML, Laufhistorie im
Anwendungslog und Mechanismus.

## P8: Wrapper-Smoketest mit Argument-Weiterreichung

Vorbefund: Das Runtime-`run-hidden.vbs` reichte nur `WScript.Arguments(0)`
weiter; Flags wie `-Apply` waeren verloren gegangen. Fix zuerst im Repo
geschrieben, dann in die Runtime kopiert ( deploy.ps1-Logik, KEEP-Regel
bewusst fuer diesen einen Zweck ueberschrieben: fix-first ).

Testaufbau: Temp-Skript `wd-smoke.ps1` mit `param([switch]$Apply)`, das
`apply=$Apply` in eine Ergebnisdatei schreibt; Aufruf:
`wscript.exe //B //Nologo run-hidden.vbs wd-smoke.ps1 "-Apply"`.

Erster Lauf (param([string]$Flag)): `flag=` (leer). Lehrstück: Switch-
Parameter binden `-Apply` nicht an String-Parameter. Zweiter Lauf mit
`param([switch]$Apply)`: **`apply=True`**.

Schluss: Weiterreichung funktioniert; der echte Watchdog deklariert
`[switch]$Apply` (Zeile 25 des Skripts verifiziert), daher bindet der
Live-Aufruf das Flag korrekt.

## P9: XML-Round-Trip des Live-Tasks

Schritte:
1. `schtasks /query /tn 'Node Watchdog' /xml` -> `02-beweise/node-watchdog-VORHER.xml`
   (Beweis: `<Command>powershell.exe</Command>`, `<Interval>PT10M</Interval>`)
2. Regex-Patch von Command + Arguments auf den Wrapper-Aufruf,
   XML-Validierung via `[xml]`-Cast, -> `node-watchdog-NACHHER.xml`
3. `schtasks /create /tn 'Node Watchdog' /xml ... /f` -> ERFOLGREICH
4. Live-Verifikation: `Action: wscript.exe //B //Nologo "...run-hidden.vbs"
   "...node-watchdog.ps1" "-Apply"`, State=Ready, LastResult=0x0

Schluss: Der Live-Task laeuft jetzt flash-frei. Trigger, Principal,
Settings sind aus der VORHER-XML unverändert uebernommen (Round-Trip).

## P10: Repo-Backup aktualisiert

Befehl: Export des Live-XML nach `task/Node Watchdog.xml` im Repo.
Ergebnis: `<Command>wscript.exe</Command>` mit Wrapper-Arguments; git
zeigt die erwarteten vier Aenderungen (install-task.ps1, task-XML neu,
audit/ neu, run-hidden.vbs neu).

## P11 - Nachtrag: Rest-Migration + Historie (2026-10-01, Slices 2-5)

Befund 12:34: MemoryIngest lief um 12:30:01 noch mit direktem powershell.exe
(LastRun-Check) - zweiter aktiver Blitzer nach dem Watchdog-Fix.

Schritte (Skript: audit/2026-10-01-fenster-flash/migrate-tasks.ps1):
- VORHER-XMLs aller vier Tasks gesichert (02-beweise/migration/VORHER-*.xml)
- XML-Round-Trip je Task (Command/Arguments -> wscript.exe run-hidden.vbs,
  Rest byte-identisch, [xml]-Validierung, schtasks /create /xml /f)
- RoutedWatch: vorher Stop-ScheduledTask (war Running), danach Start ->
  State=Running, Watch-Log: Watcher gestartet 13:13:13 (PID 24580)
- Live-Check: 4/4 Exec=wscript.exe (migration-livecheck.txt);
  RoutedWatch Result 0xC000013A = Status des Stop-Abbruchs, nach Neustart 0x41301 (Running)
- Historie: wevtutil set-log /enabled:true (Admin-Erhoehung, Operator-approved),
  get-log -> enabled: true; erste Events fliessen (13:20:01 Watchdog-Lauf)
- Repo-Backups task/*.xml neu exportiert (6/6 auf wscript.exe)
- Selbstpruefung erweitert (Pruefungen 7 + 10): 22/22 PASS

## P12 - Nachtrag: MemoryIngest-16:30-Lauf flash-frei (2026-10-01)

Erster regelmaessiger Lauf von MemoryIngest nach der Rest-Migration
(P11 - der 12:30-Lauf lief noch auf direktem powershell.exe).

Beweis (Skript: memoryingest-1630-verifikation.ps1, Beweisdatei
02-beweise/migration/memoryingest-1630-verifikation.txt):

- Live-Aktion: `wscript.exe //B //Nologo "...run-hidden.vbs"
  "...ingest.ps1"` (Wrapper-Nachweis)
- 16:30:01 Task gestartet (Events 100/107/129, PID 8140, Aktion
  wscript.exe)
- 16:30:16 Task erfolgreich abgeschlossen, Rueckgabecode 0 (Events
  102/201)
- Get-ScheduledTaskInfo: LastRunTime 16:30:01, LastTaskResult 0 (0x0),
  NumberOfMissedRuns 0
- Runtime-Log: Ingest abgeschlossen (10 Dateien bereits gefilmt, 0 neu),
  Endzeit 16:30:15

Schluss: Auch der 4-h-Task laeuft flash-frei. Die Migration ist damit an
allen zeitgesteuerten Vertretern durchlaufen (Watchdog 10 min,
MemoryIngest 4 h, naechtliche Cleanups nach gleichem Muster, RoutedWatch
AtLogon). Operative Grenze bleibt: Fensterlosigkeit ist strukturell
bewiesen (SW_HIDE ab Prozessstart) und durch die Operator-Beobachtung
getragen, nicht durch Screenshot-Telemetrie.
