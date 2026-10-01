# ADR-014: Task-Aktionen laufen ueber run-hidden.vbs statt direkt PowerShell

## Status

Accepted

## Date

2026-10-01

## Context

Seit dem Start der Task-as-Code-Suite blitzte bei jedem Scheduled-Task-Lauf
ein PowerShell-Konsolenfenster auf (Wahrnehmung: alle ~15 Minuten). Ursache:
Die Task-Aktionen starteten direkt `powershell.exe -WindowStyle Hidden`.
PowerShell ist eine Konsolenanwendung; Windows erzeugt das conhost-Fenster,
bevor der Hidden-Schalter verarbeitet wird. Der Schalter versteckt also ein
Fenster, das zu diesem Zeitpunkt bereits sichtbar war (ca. 0.5 s Flash).

Betroffen waren alle fuenf eigenen Tasks: Node Watchdog (alle 10 Minuten,
dadurch Sichtbarkeit des Stoerers), MemoryIngest (alle 4 h), NpmCleanup
(taeglich 03:00), ToolingCleanup (taeglich 04:00), RoutedWatch (AtLogon,
dauerhaft laufend).

## Decision

1. **Alle Scheduled-Task-Aktionen laufen ueber den VBS-Wrapper:**
   `wscript.exe //B //Nologo "%USERPROFILE%\.tools\maintenance\run-hidden.vbs" "<skript.ps1>" [args]`.
   `WScript.Shell.Run cmd, 0, True` (SW_HIDE) startet den Kindprozess ab dem
   ersten Befehl ohne Fenster; die Argumente 1..n werden gequoted
   durchgereicht (inkl. Watchdog-`-Apply`).
2. **`install-task.ps1` erzeugt nur noch Wrapper-Aktionen.** Eine neue
   Task-Registrierung kann den Fehler nicht wieder einfuehren.
3. **Bestehende Tasks wurden per XML-Round-Trip migriert** (Command/Arguments
   gepatcht, Trigger/Principal/Settings byte-identisch uebernommen); die
   Repo-Backups in `task/` spiegeln den Live-Stand (6/6 XMLs auf
   wscript.exe, inkl. bewusst archiviertem Fremd-Task).
4. **Nachweis-Regel:** Die TaskScheduler-Operational-Historie bleibt
   aktiviert; Lauf-Verifikation geht ueber `Get-ScheduledTaskInfo` plus
   Event-Log, nicht ueber Sichtbarkeits-Annahmen.

## Alternatives Considered

### `-WindowStyle Hidden` beibehalten und Flash akzeptieren
- Pros: keine Aenderung
- Cons: Der Flash war genau das gemeldete Problem; der Schalter greift zu spaet
- Rejected: verfehlt den Zweck

### GUI-Haekchen "Ausgeblendet" am Task
- Pros: Einstellung direkt in der Aufgabenplanung
- Cons: Das Haekchen versteckt nur das Task-Icon, nicht das conhost-Fenster
  des Kindprozesses
- Rejected: behebt die Ursache nicht

### Wrapper als .cmd mit `start /min`
- Pros: kein VBScript
- Cons: cmd.exe ist selbst eine Konsolenanwendung und erzeugt wieder ein
  Fenster, bevor `start /min` greift
- Rejected: gleiches Problem, eine Ebene verschoben

### CreateProcess mit CREATE_NO_WINDOW (C#-Inline oder Extra-Binary)
- Pros: ganz ohne VBScript
- Cons: erfordert Inline-Compile oder eine eigene Binary je Task; die
  Task-Aktion wird in der XML unlesbar
- Rejected: Komplexitaet ohne Mehrwert, wscript ist Windows-Bordmittel

## Consequences

- Kein Fenster-Flash mehr bei allen fuenf Tasks (strukturell bewiesen:
  SW_HIDE ab Prozessstart), bestaetigt durch Watchdog-Regellauf und
  Smoketest; Verifikation des 16:30-MemoryIngest-Laufs folgt im
  Audit-Paket (P12).
- `run-hidden.vbs` ist Bestandteil der Runtime
  (`%USERPROFILE%\.tools\maintenance\`) und wird von `deploy.ps1`
  gespiegelt; ohne Deployment-Update bleibt der Wrapper fuer neu
  registrierte Tasks unveraenderlich unsichtbar wirksam.
- Der Wrapper wartet synchron (`True`): der Task bleibt "Running", solange
  das Skript laeuft - ExecutionTimeLimit und IgnoreNew greifen weiterhin.
- Audit-Paket mit voller Beweiskette: `audit/2026-10-01-fenster-flash/`
  (Protokoll, Entscheidungslog, Selbstpruefung 22/22 PASS).

## Related

- `audit/2026-10-01-fenster-flash/` (Beweiskette, Entscheidungslog E1-E6)
- ADR-007 (Memory-Ingest als Scheduled Task - betroffener Task)
- `maintenance/run-hidden.vbs` (Wrapper, Begruendung im Dateikopf)
- `scripts/install-task.ps1` (Durchsetzung fuer neue Registrierungen)
- PRs #66/#67 (Fix- und CI-Nachlauf)
