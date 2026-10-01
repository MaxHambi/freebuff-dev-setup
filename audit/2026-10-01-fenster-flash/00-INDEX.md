# Audit: Fenster-Flash durch Scheduled Tasks (2026-10-01)

## Verdict

Der PowerShell-Fenster-Flash (Wahrnehmung: alle ~15 Minuten) geht auf die
Scheduled Task **Node Watchdog** zurueck: Trigger `TimeTrigger Interval=PT10M`
(10-Minuten-Raster), Aktion startete **direkt** `powershell.exe -WindowStyle
Hidden`. Windows erzeugt das conhost-Fenster einer Konsolenanwendung, bevor
PowerShell den Hidden-Schalter verarbeitet; daraus der kurze Flash mitten auf
dem Desktop. Der Fix stellt die Task-Aktion auf den flash-freien
`wscript.exe run-hidden.vbs`-Wrapper um (SW_HIDE ab Prozessstart).

## Fix-Status

- Repo: `maintenance/run-hidden.vbs` neu (Argument-Weiterreichung 1..n),
  `scripts/install-task.ps1` auf Wrapper-Muster umgestellt (alle Tasks),
  `task/Node Watchdog.xml` aktualisiert
- Live: nur der Stoerer-Task "Node Watchdog" wurde per XML-Round-Trip
  umgestellt (Trigger/Principal/Settings byte-identisch uebernommen)
- Verifikation: Wrapper-Smoketest (`apply=True`) + erster regelmaessiger
  Lauf nach dem Patch (Logzeile im Watchdog-Log)

## Dateikarte

| Datei | Inhalt |
|---|---|
| `01-protokoll.md` | Chronologisches Protokoll aller Untersuchungsschritte (P1-P10) mit Befehl, Auszug, Zweck, Schlussfolgerung |
| `02-beweise/` | Rohdaten: VORHER/NACHHER-XML, Watchdog-Log-Snapshot, Original-Wrapper, Task-Inventar, Smoketest |
| `03-entscheidungen.md` | Entscheidungslog E1-E6 mit Alternativen und Begruendung |
| `04-blueprint.md` | Genehmigter Plan (v2) in der umgesetzten Fassung |
| `05-selbstpruefung.md` | Anleitung fuer menschliche Nachpruefung ohne KI-Agent |
| `99-selbstpruefung.ps1` | Read-only Pruefskript (nur Abfragen, keine Aenderungen) |
| `06-grenzen.md` | Ehrliche Grenzen: was nicht als Artefakt exportierbar ist |

## Pruefpfad (Empfehlung)

1. `01-protokoll.md` lesen (P1-P6 genuegen fuer die Beweiskette)
2. `02-beweise/node-watchdog-VORHER.xml` oeffnen: `<Interval>PT10M</Interval>`
   und `<Command>powershell.exe</Command>` sehen
3. `05-selbstpruefung.md` folgen: eigene Live-Pruefung per
   `99-selbstpruefung.ps1` (read-only) oder einzeln per Hand
4. Bei Abweichungen: `06-grenzen.md` und `03-entscheidungen.md` konsultieren
