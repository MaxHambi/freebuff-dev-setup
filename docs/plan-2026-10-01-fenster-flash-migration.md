# Plan: Fenster-Flash-Migration Rest-Tasks + Merge + Historie (2026-10-01, rev. 1 - Blueprint)

> **Quelle:** Operator-Auftraege vom 01.10.2026 (Chat): Merge des Watchdog-Fixes,
> Migration der uebrigen vier Tasks, Aktivierung der TaskScheduler-Historie,
> Feature-Abschluss. Ausloeser: erneuter Flash gegen 12:34.
> **Vorgaenger:** `audit/2026-10-01-fenster-flash/` (Watchdog-Fix, 3 Commits auf
> `fix/task-window-flash`: `78f9890` Fix, `cb2e4d8` Audit, `d86c735` Spec-Closure).
> Dieser Plan bleibt bis zum Abschluss (Slice 7) an dieser Stelle; Aenderungen
> nur als eigener Commit mit Begruendung.
>
> **Blueprint-Regel:** Jeder Slice ist cold-start-faehig. Ein frischer Agent
> (oder der Operator selbst) fuehrt den Slice ohne Sitzungshistorie aus; alle
> noetigen Pfade, Befehle, Beweise und Rollbacks stehen im Slice. Jeder Slice
> endet mit Artefakten, die ohne KI pruefbar sind (Erweiterung von
> `audit/2026-10-01-fenster-flash/05-selbstpruefung.md` + `99-selbstpruefung.ps1`).

## Ausgangsbefunde (bewiesen am 01.10.2026, read-only)

- Watchdog-Fix wirkt: `12:30:01`-Lauf des "Node Watchdog" via `wscript.exe`
  (Action-Check), `LastTaskResult 0x0`, Logzeile fehlt nicht.
- **Neuer Flash ~12:34 bewiesen:** Um `12:30:01` lief parallel **MemoryIngest**
  noch mit **direktem `powershell.exe`** (LastRun-Check 12:34 Uhr). 4-h-Intervall
  (`04:30 / 08:30 / 12:30 / 16:30 / 20:30 / 00:30`) -> MemoryIngest ist der
  aktuell aktive zweite Blitzer.
- Gleicher Defekt (direktes PowerShell) bei `NpmCleanup` (03:00), `ToolingCleanup`
  (04:00) und `RoutedWatch` (AtLogon, letzte Ausfuehrung 10:49).
- TaskScheduler-Historie ist deaktiviert (Audit P7) -> Vorfaelle bis zur
  Aktivierung nur ueber LastRun/Log-Raster beweisbar.

## Workflow-Geruest (gilt fuer alle Slices)

1. Arbeitsbranch `fix/task-window-flash` (existiert); Slice 1 merged ihn; alle
   weiteren Slices laufen auf `master` nach Pull.
2. Beweis-Artefakte je Slice nach `audit/2026-10-01-fenster-flash/02-beweise/migration/`.
3. Conventional Commits (`fix(tasks): ...`, `docs(audit): ...`, `chore(ops): ...`)
   mit Footer `Generated with Codebuff` + `Co-Authored-By: Codebuff <noreply@codebuff.com>`;
   nur slice-zugehoerige Pfade stagen, keine Sammel-Commits.
4. Nach jedem Code-/Repo-Slice: `npm run verify` muss gruen sein.
5. Rollback je Slice separat ausgewiesen; VORHER-XMLs sind die Rueckkehrebene.

## Slices (Reihenfolge verbindlich; Parallelitaet in Klammern)

### Slice 0 - Plan-Datei (dieser Commit)
- [x] Blueprint als `docs/plan-2026-10-01-fenster-flash-migration.md` abgelegt
- [x] Commit auf `fix/task-window-flash` (`docs(plan): ...`)
- Beweis: Commit-SHA + Plan-Datei im Repo.

### Slice 1 - Merge des Fix via PR (Squash) [vor allem anderen]
- Ziel: 4 Commits des Fix-Branches (3 + Plan) als ein Squash-Commit auf `master`.
- Schritte:
  1. `git push -u origin fix/task-window-flash`
  2. `gh pr create --base master --head fix/task-window-flash --title "fix(tasks): Task-Aktionen ueber run-hidden.vbs-Wrapper statt direktem PowerShell-Start" --body-file <tmp>` (Body: Summary, Verification, Beweis-Verweis `audit/2026-10-01-fenster-flash/`)
  3. `gh pr merge --squash --delete-branch` (Merge-Commit = PR-Titel)
  4. `git checkout master && git pull`
- Beweis: PR-URL, Merge-SHA, `git log --oneline -1` mit Footer.
- Rollback: `git revert <merge-sha>` auf master; Live-Task bleibt davon unberuehrt.

### Slice 2 - MemoryIngest auf Wrapper (hoechste Prioritaet: aktiver Blitzer)
- Cold-Start-Brief: Runtime-Skript `%USERPROFILE%\.tools\memory-ingest\ingest.ps1`,
  Wrapper `%USERPROFILE%\.tools\maintenance\run-hidden.vbs` (Argument-Weiterreichung
  1..n bereits gefixt), Trigger `Interval=PT4H` bleibt unveraendert.
- Schritte:
  1. `schtasks /query /tn MemoryIngest /xml` -> `02-beweise/migration/VORHER-MemoryIngest.xml`
  2. XML-Patch nur `<Command>` -> `wscript.exe` und `<Arguments>` ->
     `//B //Nologo "<vbs>" "<ingest.ps1>"`; Validierung via `[xml]`-Cast.
  3. `schtasks /create /tn MemoryIngest /xml <NACHHER> /f`
  4. Live-Check: `Exec=wscript.exe`, State=Ready; Repo-Backup
     `task/MemoryIngest.xml` neu exportieren.
- Beweis: VORHER/NACHHER-XML + LastRun/Exec-Zeile im Pruefausdruck.
- Rollback: VORHER-XML re-importieren.
- Hinweis: kein Stop noetig (Kurzlauf-Task); 12:30-Lauf ist bereits verstrichen,
  erster Wrapper-Lauf 16:30 - Zwischenverifikation via manuellem
  `Start-ScheduledTask` erlaubt, aber nicht Pflicht (Operator-Entscheid).

### Slice 3 - NpmCleanup + ToolingCleanup auf Wrapper [parallel zu Slice 2 moeglich]
- Analog Slice 2, Skripte `%USERPROFILE%\.tools\maintenance\npm-cleanup.ps1`
  bzw. `tooling-cleanup.ps1`, taegliche Trigger 03:00/04:00 bleiben unveraendert.
- Besonderheit: beide Tasks nutzen dasselbe `run-hidden.vbs`; diesmal ohne
  zusaetzliche Argumente (kein `-Apply`-Aequivalent vorhanden).
- Beweis/Rollback wie Slice 2 (VORHER-XMLs je Task).

### Slice 4 - RoutedWatch auf Wrapper [nach Slice 2/3, gleicher Mechanismus]
- Cold-Start-Brief: Dauerprozess (AtLogon, IgnoreNew, ExecutionTimeLimit 0).
- Schritte:
  1. VORHER-XML sichern (wie oben).
  2. `Stop-ScheduledTask -TaskName RoutedWatch` (laufende Instanz beenden).
  3. XML-Patch + Re-Import + `Start-ScheduledTask RoutedWatch`.
  4. Live-Check: Prozess laeuft wieder, `Exec=wscript.exe`.
- Beweis/Rollback wie Slice 2; Zusatzbeweis: Routed-Watch-Log (`%LOCALAPPDATA%\Routed\watch.log` bzw. `.tools\routed-watch\`) schreibt nach Neustart weiter.

### Slice 5 - TaskScheduler-Historie aktivieren
- `wevtutil set-log Microsoft-Windows-TaskScheduler/Operational /enabled:true`
- Verifikation:
  1. `wevtutil get-log Microsoft-Windows-TaskScheduler/Operational` -> `enabled: true`
  2. Nach dem naechsten Task-Lauf:
     `Get-WinEvent -LogName Microsoft-Windows-TaskScheduler/Operational -MaxEvents 5`
     -> Event-ID 100 (Start) / 129 (Erstellt) sichtbar.
- Beweis: Log-Status-Ausgabe + erster Event-Dump als Datei im migrations-Ordner.
- Rollback: `/enabled:false` (nicht gewuenscht; Historie bleibt an).

### Slice 6 - Selbstpruefung erweitern + Audit-Schluss
- `99-selbstpruefung.ps1` ergaenzen:
  - Pruefung 7b: alle vier migrierten Tasks mit `Exec=wscript.exe` + VORHER/NACHHER-XML vorhanden
  - Pruefung 10: Historie aktiv + erster Event-Nachweis
- `05-selbstpruefung.md` um die neuen Pruefungen ergaenzen; `06-grenzen.md`
  Abschnitt Historie aktualisieren (ab Datum beweisbar).
- Commit `docs(audit): ...`; danach `npm run verify`.
- Beweis: Selbstpruef-Ausdruck `11+N PASS, 0 FAIL` als Datei.

### Slice 7 - Feature-Abschluss (/complete)
- `blueprint/context/current-feature.md`: Rest-Migration + Historie in den
  Done-when-Block aufnehmen, alle Haken mit Beweis versehen.
- Spec nach `blueprint/history/fixes/` archivieren (Nummerierung nach
  `blueprint/history/fixes/README.md`), `current-feature.md` auf Stub zuruecksetzen.
- CHANGELOG `[Unreleased]` Fixed-Eintrag um Rest-Migration + Historie erweitern.
- `npm run verify` gruen; Abschluss-Commit `docs(history): ...`.
- MemPalace: Ergebnis-Drawer (Fenster-Flash Root-Cause + Fix + Migration,
  Identity `maxhambi:freebuff:freebuff-dev-setup`) sowie `mempalace_kg_add`
  fuer die Regel "Task-Aktionen immer via run-hidden.vbs".
- Kein Push ohne separates Operator-OK.

## Auditierbarkeits-Matrix

| Slice | Artefakt | Pruefung ohne KI |
|---|---|---|
| 1 | PR-URL, Merge-SHA | `gh pr view`, `git log` |
| 2-4 | VORHER/NACHHER-XMLs je Task + `task\`-Backups | XML-Diff, `Get-ScheduledTask ... Actions[0].Execute` |
| 5 | Log-Status + Event-Dump | `wevtutil get-log`, `Get-WinEvent` |
| 6 | Erweiterter Selbstpruef-Ausdruck | `pwsh -File 99-selbstpruefung.ps1` (read-only) |
| 7 | History-Datei, CHANGELOG, MemPalace-Drawer | Datei-Lektuere, `mempalace search` |

## Explizit unangetastet

Watchdog-Logik/Intervalle · Trigger-/Settings-Blöcke aller Tasks (byte-identisch
uebernommen) · Drittanbieter-Tasks (cua-driver-serve, Hermes_Gateway, MiTeC,
OneDrive, PowerToys) · deskreen-Repo
