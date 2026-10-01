# Selbstpruefung (ohne KI-Agent)

Ziel: Du pruefst jede Aussage des Audits selbst nach, nur mit Windows-
Bordmitteln. Alle Befehle sind read-only, sie veraendern nichts. Entweder
einzeln per Hand oder gebuendelt ueber `99-selbstpruefung.ps1` (ebenfalls
read-only).

## Pruefung 1: Live-Task nutzt den Wrapper

PowerShell oeffnen und ausfuehren:

```powershell
$t = Get-ScheduledTask -TaskName 'Node Watchdog'
$t.Actions[0].Execute
$t.Actions[0].Arguments
```

Erwartet: `wscript.exe` sowie Arguments mit `//B //Nologo`, dem Pfad zu
`run-hidden.vbs`, dem Pfad zu `node-watchdog.ps1` und `-Apply`.
Taete der Fix nicht, stuende hier `powershell.exe`.

## Pruefung 2: Trigger-Intervall unveraendert 10 Minuten

```powershell
(Get-ScheduledTask -TaskName 'Node Watchdog').Triggers[0].Repetition.Interval
```

Erwartet: `PT10M`. Identisch zur VORHER-XML
(`02-beweise/node-watchdog-VORHER.xml`), der Fix aendert nur die Aktion.

## Pruefung 3: Laufhistorie im 10-Minuten-Raster (Beweis Rhythmus)

```powershell
Get-Content "$env:USERPROFILE\.tools\node-watchdog\node-watchdog.log" -Tail 30
```

Erwartet: `Start: Mode=APPLY`-Zeilen im 10-Minuten-Abstand, Startzeit
jeweils um xx:xx:02 (Scheduler-Feuer). Das erklaert die Wahrnehmung
"rund alle 15 Minuten": real sind es 10.

## Pruefung 4: Letzter Task-Lauf erfolgreich

```powershell
Get-ScheduledTaskInfo -TaskName 'Node Watchdog' | Select LastRunTime, LastTaskResult
```

Erwartet: `LastTaskResult` = 0 (bzw. 267009 = laeuft gerade). Ein von
dir beobachteter Lauf nach dem Fix muss nach diesem Fix mit 0 enden.

## Pruefung 5: VORHER/NACHHER-Vergleich

Beide XML-Dateien in `02-beweise/` oeffnen (z. B. in einem Editor, der
UTF-16 liest) und vergleichen:
- `node-watchdog-VORHER.xml`: `<Command>powershell.exe</Command>`
- `node-watchdog-NACHHER.xml`: `<Command>wscript.exe</Command>`
- Identisch sein muessen: `<Interval>PT10M</Interval>`, `<UserId>`,
  `<LogonType>`, `<ExecutionTimeLimit>PT5M</ExecutionTimeLimit>`,
  `<StartWhenAvailable>true</StartWhenAvailable>`

## Pruefung 6: Repo-Muster (install-task.ps1)

```powershell
Select-String -Path "D:\freebuff-dev-setup\scripts\install-task.ps1" -Pattern "wscript"
```

Erwartet: die Wrapper-Aktionszeile im Standardpfad und im AtLogon-Zweig.
Damit gilt das Fix-Muster fuer alle kuenftigen Task-Registrierungen.

## Pruefung 7: Kein Flash mehr (subjektiv)

Arbeite 10-15 Minuten am Rechner. Bis zum Fix haette der Watchdog in
jedem 10-Minuten-Fenster genau einmal ein PowerShell-Fenster kurz
aufblitzen lassen. Nach dem Fix: kein Blitz. (Ein einziger Watchdog-Lauf
zwischen deinen Beobachtungen genuegt als Negativ-Beweis.)

## Rollback (nur falls gewuenscht, nicht Teil der read-only Pruefung)

```powershell
schtasks /create /tn "Node Watchdog" /xml "<pfad>\02-beweise\node-watchdog-VORHER.xml" /f
```
