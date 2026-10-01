# Blueprint (v2, genehmigt): Fenster-Flash beheben + Audit-Paket

> Abgenommene Planfassung vom 2026-10-01. Umgesetzt wie beschrieben; die
> Abweichungen (Repo-Pfad, Wrapper-Lage, vbs-Erweiterung) sind in
> `03-entscheidungen.md` E3/E5 dokumentiert.

## Feedback-Punkte, eingebaut

1. **Ausfuehrung nur wenn noetig:** Live wird ausschliesslich der eine
   Stoerer-Task ("Node Watchdog") umgestellt. Keine erzwungenen manuellen
   Testlaeufe; Verifikation am ersten regelmaessigen ueberwachenden Lauf.
2. **Audit-Paket:** Der gesamte Ablauf wird menschenpruefbar gesichert;
   das Audit fuehrt der User selbst durch, ohne KI-Agent.

## Beweisstand (kondensiert)

- Taeter: Task "Node Watchdog", `TimeTrigger Interval=PT10M`
- Lauf-Raster im Watchdog-Log: 00:40 / 00:50 / 01:00 / 01:10 / 01:20 / 01:30
- Mechanismus: direkter `powershell.exe`-Start erzeugt conhost sichtbar,
  bevor `-WindowStyle Hidden` greift (Flash ca. 300-500 ms)
- Ursache: Migrations-Sitzung ersetzte das flash-freie `run-hidden.vbs`-
  Muster durch direkte PowerShell-Aufrufe; Wrapper lag ungenutzt
- Ausgeschlossen: MemoryIngest (4 h), Npm/ToolingCleanup (naechtlich),
  RoutedWatch/cua/Hermes (nur Logon), Microsoft-Tasks, WMI-Consumer
- TaskScheduler-Historie deaktiviert (Dreifach-Beweis ueber Trigger,
  Log-Raster, Mechanismus)

## Umsetzung (Reihenfolge, mit Audit-Mitprotokollierung ab Schritt 1)

1. Repo neu einlesen (Implementierungs-Sitzung hatte committet; Repo inzwischen
   `D:\freebuff-dev-setup`, ehemals tools-entwicklung)
2. Audit-Ordner anlegen; Protokoll der bisherigen Schritte nachtragen
3. `maintenance/run-hidden.vbs` erweitern: alle Argumente (1..n) gequoted
   weiterreichen (aktuell nur Arguments(0))
4. `scripts/install-task.ps1`-Mapping auf wscript-Muster umstellen
5. Deploy: nur run-hidden.vbs + node-watchdog nach `.tools`
6. Live nur "Node Watchdog": Original-XML sichern, Command/Arguments patchen,
   Re-Registrierung aus XML (Trigger/Principal/Settings byte-identisch)
7. Task-XML-Backup nach `task\` exportieren
8. Gate: `npm run verify` -> atomic Commits (fix + audit)
9. Verifikation am ersten regelmaessigen Lauf: neue Logzeile + LastTaskResult
   0x0 + kein Fenster-Flash in der Arbeitsphase (User-Bestaetigung)
10. Optional: TaskScheduler-Historie aktivieren (auf Zuruf)

## Rollback

VORHER-XML (`02-beweise/node-watchdog-VORHER.xml`) per
`schtasks /create /tn "Node Watchdog" /xml <datei> /f` zurueckspielen;
Task laeuft exakt wie vor dem Fix.

## Explizit unangetastet

deskreen-Repo samt Branch `feature/issue-2-citty-cli-skeleton` ·
Watchdog-Logik/Whitelist/Intervalle · die 4 uebrigen Live-Tasks (nur
Repo-Muster) · Drittanbieter-Tasks (cua-driver-serve, Hermes_Gateway,
MiTeC, OneDrive, PowerToys)
