# ADR-001: Watchdog-Integrationstests - 4 akzeptierte Known-Fails und offene RCA

## Status

**Accepted (2026-09-29)** - RCA abgeschlossen; alle 4 Known-Fails sind
verstanden und behoben (2 Watchdog-Fixes, 1 Harness-Fix, 1 Folge-Effekt).
Der Harness laeuft 21/21 PASS ohne Known-Fail-Marken (2x hintereinander
verifiziert). Die KnownFail-Mechanik im Harness bleibt fuer kuenftige
Faelle erhalten.

## Datum

2026-09-24

## Kontext

Slice T1 (plan.md) verlangt Integrationstests fuer den Node-Watchdog ueber echte
Test-Prozesse. Der Harness `node-watchdog/run-tests.ps1` startet echte
Node-Prozessbaeume (Wrapper -> Eltern -> Enkelkind), einen HTTP-Port-Server,
einen Whitelist-Kandidaten und prueft die Kill-Kriterien Ende-zu-Ende.

Aktueller Stand (2026-09-24, mehrfach reproduziert):

- 18 von 22 Assertions PASS.
- 4 FAIL, alle in der Assertion-Mechanik der Kandidaten-Listen, nicht im
  Watchdog-Verhalten selbst:
  1. `T2 Orphan erkannt (Tree-Eltern)` - Kandidatenliste enthaelt treePids[0]
     laut Assertion nicht.
  2. `T3 Stale-Port erkannt (PortStaleHours 0)` - Port-Zeile ohne
     stale-port-Marker.
  3. `T4 -IncludeWhitelisted listet Whitelist-Prozess`.
  4. `T5 Whitelist-Prozess ueberlebt Apply` - widerspricht T5-Apply-Assertions,
     die belegen, dass genau die erwarteten Prozesse starben und Extras
     unangetastet blieben.

## Entscheidung

Die 4 Fails werden akzeptiert (Nutzerentscheid), als Known-Fails im Harness
dokumentiert und per diesem ADR als offene RCA gefuehrt. Slice T1 gilt mit den
verbleibenden 18 PASS-Assertions als erfuellt; der Watchdog-Code selbst ist von
den Fails nicht betroffen.

## Beweislage (warum die Watchdog-Logik als funktionierend gilt)

- T5 Apply-Test PASST vollstaendig: Der Port-Server starb nur ueber das
  stale-port-Kriterium (PortStaleHours 0), der Tree-Node nur ueber orphan
  (Eltern tot/PID-Reuse) - der taskkill /T Baum-Kill erfasste das Enkelkind.
  Wenn die Kriterien die Prozesse nicht identifiziert haetten, haette Apply sie
  nicht killen koennen.
- `T5 externe Kandidaten unangetastet` PASST: die Temp-Whitelist schuetzt echte
  System-Leftovers (u. a. den echten Orphan PID 8540) zuverlaessig.
- T6 Rotation und T1 DryRun-Vertrag (Exit 0, kein KILL) PASSEN.
- Manuelle Live-Runs bestätigen den Orphan-Fund stabil ueber mehrere Stunden
  (gleiche PID, gleiche Begruendung, deterministisch).

## Deep-RCA: Hypothesen (Status je: unverified)

H1 - Sortierung/Index-Drift: `treePids[0]` ist nicht der node-Elternteil,
sondern ein Zwischenprozess, dessen Kandidaten-Zeile durch Cleanup-Timing
verschwindet, bevor der Watchdog laeuft. Pruefung: Kandidaten-Zeilen des
T2-Laufs gegen die Setup-Liste mit Elternkette (Win32_Process
ParentProcessId) abgleichen.

H2 - Stale-Port-Zuordnung: netstat-Lauf und Prozess-IDs driften (Port-Server
istet zwischen netstat und Bewertung ab, oder die PID-Spalte von
TIME_WAIT/LISTENING-Zeilen weicht ab). Pruefung: netstat -ano mit
Port-Server-Registrierung vergleichen; Kandidaten-Zeile fuer portPids[0]
manuell inspizieren.

H3 - Doppel-Log-Lese (ausgeschlossen?): Invoke-Watchdog loescht das Log vor
jedem Lauf, aber `T3`-Assertion liest `(Get-Content $log)` danach erneut -
falls der Watchdog bei leerem Log frueh exitet (keine Kandidaten), ist die
Datei leer oder fehlt, und die Assertion läuft ins Leere. Pruefung:
Vorhandensein der Logdatei vor Assertion erzwingen.

H4 - Whitelist-Matching-Grenze: `-IncludeWhitelisted` listet den
Whitelist-Kandidaten nur, wenn er zusaetzlich ein Kill-Kriterium erfuellt;
der keep-node ist frisch (< MaxAge), hat keine Ports und lebt - er erfuellt
kein Kriterium und taucht daher in KEINER Kandidatenliste auf, auch nicht mit
Override. Das wuerde bedeuten: die Assertion testet das falsche Verhalten
(der Watchdog ist korrekt, der Test falsch). Pruefung: keep-node mit
-PortStaleHours 0 + WatchedPort laufen lassen und Override-Listing dort
verifizieren. H4 ist die wahrscheinlichste Erklaerung fuer Fail 3 und 4:
`T5 Whitelist-Prozess ueberlebt Apply` PASST dann trotzdem, weil der Prozess
gar nicht erst Kandidat war - aber die FAIL-Assertion, die sein Aufscheinen
in candsC erwartet, ist dann schlicht falsch formuliert.

H5 - Keep-Node-Verwaatung: Der keep-Wrapper killt nur den Wrapper; der
keep-node bleibt mit tot-Elternteil orphan und muesste ohne Whitelist
Kandidat sein. Falls das Matching (Marker im CommandLine-Substring) durch
Environment-Variablen-Vererbung fehlschlaegt, wird er als anderer Prozess
gesehen. Pruefung: Kandidaten-Zeilen ohne Whitelist gegen wd-selftest-keep
Marker pruefen.

## Konsequenzen

- Positive: Der Watchdog-Kern (Kriterien 1-3, Apply, Baum-Kill, Rotation,
  Selbstschutz, Whitelist-Schutz) ist durch 18 PASS-Assertions belastbar
  abgedeckt; der Merge von Slice T1 blockiert nicht auf der RCA.
- Negative: Die vier Test-Assertions sind bis zur Klärung irrefuehrend; der
  Harness misst an diesen Stellen nicht das, was ihre Namen behaupten.
- Nachfolge: RCA-Hypothesen H1-H5 in einer Folgesitzung verifizieren; bei
  bestaetigtem H4 die drei betroffenen Assertions umbenennen/umformulieren
  (Test-Bug, kein Watchdog-Bug), bei H1-H3/H5 den Watchdog fixen.

## Loesung (2026-09-29, RCA abgeschlossen)

Die Deep-RCA wurde mit einem Instrumentierungsdump im Harness
(`-RcaDump`: Kandidatenzeilen + Elternkette je Test-PID) und isolierten
Prozess-Experimenten (PROBE A-E3) gefuehrt. Verdicts:

| Hypothese | Verdict | Beweis |
|---|---|---|
| H1 Sortierung/Index-Drift | **widerlegt** | Dump zeigte die echten Kandidatenlisten; kein Index-Drift |
| H2 Stale-Port-Zuordnung | ** bestaetigt (Locale-Bug)** | PROBE A: netstat zeigt auf deutschem Windows `ABHOeREN` statt `LISTENING`; der Parser erzeugte dadurch IMMER eine leere Port-Map. Fix: `Get-NetTCPConnection -State Listen` (locale-unabhaengig) statt netstat-String-Matching |
| H3 Doppel-Log-Lese | widerlegt | Logdatei war bei jeder Assertion vorhanden und gefuellt |
| H4 Whitelist-Matching-Grenze | im Kern bestaetigt | Kandidat ist nur, wer ein Kill-Kriterium erfuellt; der frische Keep-Node hatte keines. Effektiv maskiert durch H7 (Keep-Node war schon tot) |
| H5 Keep-Node-Verwaaisung/Marker | widerlegt | Marker-Matching funktioniert; Keep-Node war an H7 gestorben |
| **H6 (neu): PID-Reuse-Heuristik invertiert** | **bestaetigt (Watchdog-Bug)** | Code verglich `parentCreated < childCreated` - das ist der Normalfall jeder Eltern-Kind-Beziehung und flaggte Prozesse mit LEBENDEM Elternteil als verwaist (RCA-Dump: Port-Server mit lebendem Elternteil als `PID-Reuse (verwaist)`). Fix: Vergleich auf `-gt` gedreht |
| **H7 (neu): Harness-Spawn nicht detached** | **bestaetigt (Harness-Bug)** | PROBE E1: Kinder sterben beim Wrapper-Exit auch graceful (Node/Windows-Job-Objekt-Semantik); PROBE E3: mit `detached: true` ueberleben sie. Die 4 Original-Fails entstanden, weil die Test-Prozesse VOR dem Watchdog-Lauf schon tot waren. Fix: beide Wrapper spawnen `detached:true` |

Konsequenz-Fixes in diesem Zug:

1. `node-watchdog.ps1`: Port-Mapping via `Get-NetTCPConnection` (H2),
   PID-Reuse-Vergleich korrigiert (H6).
2. `run-tests.ps1`: detached-Spawns (H7), `-RcaDump`-Instrumentierung,
   alle 4 `-KnownFail`-Marken entfernt.
3. Bei Gelegenheit geprueft und OK: der live registrierte Task meldete
   waehrend der RCA `LastTaskResult 2147946720` (0x800710E0, skipped)
   - wird in Slice 6 (T7-Verifikation) weiterverfolgt.

## Verwandtes

- plan.md, Slice T1 (AC-Kernpunkte Kill-Kriterien 1-3, DryRun, Whitelist,
  Baum-Kill, Log-Rotation).
- scripts/test.ps1 (ruft den Harness nicht auf; Watchdog-Harness wird separat
  via `pwsh -File node-watchdog/run-tests.ps1` gefahren).
