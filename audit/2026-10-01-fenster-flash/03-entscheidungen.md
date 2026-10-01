# Entscheidungslog

Jede Entscheidung mit den erwogenen Alternativen und dem Grund fuer die Wahl.
Nummerierung E1-E6 fuer Referenz in P-Protokoll und Selbstpruefung.

## E1: Täter-Identifikation Node Watchdog statt MemoryIngest

Beide Tasks repetitiv + direktes powershell.exe. Entscheidung fuer Node
Watchdog wegen Intervall: 10 Minuten passt zur Wahrnehmung (~15 Minuten ohne
Zeitmessung), 4 Stunden nicht. Zudem laeuft MemoryIngest zuletzt um 00:30
(NextRun 04:30); der Flash wird dagegen kontinuierlich beobachtet.
Alternativen: RoutedWatch (1-Minuten-Trigger, aber nur Logon-Kontext und
Dauerprozess, kein Fenster-Rhythmus), Cleanup-Tasks (einmal naechtlich),
WMI-Consumer (keine CommandLine-Consumer vorhanden).

## E2: Fix ueber wscript-Wrapper statt PowerShell-eigener Versteck-Optionen

Erwogen:
- `conhost.exe --headless powershell ...` als Task-Aktion: funktioniert,
  aber dokumentationsarm, kein Vorlagen-Abgleich mit der bewaehrten
  Runtime-Datei, Verhalten bei Windows-Updates ungeprueft.
- `powershell.exe -WindowStyle Hidden` beibehalten: ist genau der Fehler.
- VBScript-Wrapper `run-hidden.vbs`: bereits als bewaehrte Vorlage in der
  Runtime vorhanden, SW_HIDE ab Prozessstart, unabhaengig von PowerShell-
  Versionen, null Abhaengigkeiten.

Entscheidung: Wrapper. Grund: bewaehrt, minimal, keine neuen Abhaengigkeiten,
und der Mechanismus (WScript.Shell.Run mit 0) ist seit Jahrzehnten stabil.

## E3: Nur der Stoerer-Task wird live umgestellt

Der Plan (v2) sieht fuer die uebrigen vier Tasks (MemoryIngest, NpmCleanup,
ToolingCleanup, RoutedWatch) nur das Repo-Muster vor. Grund: Ihr Flash-Fenster
ist praktisch unmerklich (nachts bzw. beim Logon), die Live-Aenderung haette
keinen spuerbaren Nutzen, aber je Task ein Registrierungsrisiko. Die
install-task.ps1-Mapping-Aenderung gilt fuer alle; wer will, rollt sie mit
`-Register` bei Gelegenheit aus. Die XML-Backups der vier Tasks bleiben
unveraendert und zeigen weiterhin den alten direkten powershell.exe-Aufruf,
bis sie neu registriert und neu exportiert werden.

## E4: XML-Round-Trip statt Neuregistrierung

Erwogen: `install-task.ps1 -Register` fuer den Live-Task (neue schtasks-
Erstellung + Set-ScheduledTask-Nachbesserung). Dagegen: schtasks /create
akzeptiert die Trigger-Vorlage korrekt, aber Duration (IdleSettings) und
Repetition-Dauer wären neu gesetzt, nicht byte-identisch. XML-Round-Trip:
VORHER exportieren, nur Command/Arguments patchen, NACHHER importieren.
Trigger, Principal, Settings bleiben unveraendert. Entscheidung: Round-Trip,
weil der Scope minimal und der Rollback trivial (VORHER-XML re-importieren)
ist.

## E5: Wrapper-Fix im Repo, dann Runtime-Update per Kopie

Das Runtime-`run-hidden.vbs` war bislang unversioniert. Entscheidung: Datei
ins Repo aufnehmen (maintenance/run-hidden.vbs) und von dort deployen.
Grund: Versionierung ist die Voraussetzung fuer das Audit (VORHER/NACHHER
beweisbar) und folgt der Repo-Prämisse Tasks as code. Die Kopie in die
Runtime ist eine bewusste Ausnahme von der KEEP-Regel des deploy.ps1: Ohne
Update wuerde der Live-Task das alte, fehlerhafte Wrapper-Verhalten nutzen.
Der_smoke-Test P8 beweist die Runtime-Version vor dem Live-Patch.

## E6: Audit-Ort im Repo statt ausserhalb

Alternative gewesen: %USERPROFILE%\.tools\audit\... oder ein separates
Dokument. Entscheidung: `audit/2026-10-01-fenster-flash/` im Repo, committet.
Grund: versioniert = gesichert gegen Versehentlichloeschen; die Beweiskette
(P9 XML-Round-Trip) erzeugt Artefakte, die zum Commit passen; und der
Repo-Workflow sieht Verifikation ueber Gates vor, die auf dem Repo arbeiten.
Die Selbstpruefung (05 + 99) ist bewusst read-only, damit das Audit ohne
KI-Agent lauffaehig bleibt.
