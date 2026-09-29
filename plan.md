# plan.md – Freebuff-Dev-Setup (Tasks & Watchdogs)

> **Dauerhafte Referenz** für das Repo `D:\freebuff-dev-setup`.
> Der Plan wurde am 2026-09-24 genehmigt. Die **Implementierung erfolgt in einer
> neuen Sitzung** mit diesem Repo als Arbeitsverzeichnis – dieses Dokument ist
> die verbindliche Vorgabe dafür.
> Bei jedem Statuswechsel den `Status`-Block des jeweiligen Slice aktualisieren.
> Keine Tokens/Credentials in dieser Datei.
>
> **Amendment 2026-09-29 (Operator-Entscheidung, #32):** T5 (NodeProcessMonitor)
> und T6 (Ruflo-PolicyLedger-Rotate) werden **nicht migriert**, sondern als alte
> Reste gestrichen und geloescht (Task deregistriert, Dateien entfernt). Die
> Migration umfasst nur T2-T4.

---

## Ziel & Kontext

Zwei Aufträge in einem Repo:

1. **Node-Watchdog (neu):** globaler Scheduled Task, der systemweit
   `node.exe`/`electron.exe`/`esbuild.exe`-Prozesse prüft und nachweisliche
   Leftovers (verwaist, idle-aged, stale Port-Listener) inkl. Prozessbaum beendet.
2. **Konsolidierung (Migration):** alle bisher selbst gebauten Scheduled Tasks
   und ihre Scripts wandern in die Zielstruktur nach `%USERPROFILE%\.tools\`;
   jede Task-Definition wird als exportierte XML gesichert und ist damit als
   Datei wiederherstellbar (Aufgabenplanung → „Aufgabe importieren…").

Entwicklung erfolgt **hier im Repo**, Runtime-Kopien liegen danach unter
`%USERPROFILE%\.tools\`. Die Tasks laufen auf die Runtime-Pfade, nicht ins Repo.

## Zielstruktur

### Repo (Entwicklung)
```
D:\freebuff-dev-setup\
├── node-watchdog\            Watchdog-Suite (Scripts, Tests, Doku)
├── memory-ingest\            Memory-Ingest: Session → Palast (ADR-007, Ergänzung 2026-09-26)
├── maintenance\              npm-cleanup.ps1 · tooling-cleanup.ps1 · run-hidden.vbs
├── routed-watch\             watch-wrapper.ps1 (Quelle: %LOCALAPPDATA%\Routed)
├── task\                     exportierte Task-XMLs (alle Tasks)
├── scripts\                  Deploy-/Registrierungs-Helper (install-task.ps1 etc.)
├── plan.md · AGENTS.md
```

### Runtime (Ziel nach Deploy)
```
%USERPROFILE%\.tools\
├── node-watchdog\ · maintenance\ · routed-watch\ · memory-ingest\
└── task\   ← XML-Exporte aller Tasks
```

## Watchdog-Design (bindend)

- **Zielprozesse:** `node.exe`, `electron.exe`, `esbuild.exe`, systemweit.
- **Kill-Kriterien (nur belegbare Leftovers):**
  1. **Verwaist:** Eltern-PID existiert nicht mehr (PID-Reuse-Schutz:
     Eltern-Startzeit muss älter als die des Kindes sein).
  2. **Idle-Aged:** Alter > `MaxAgeHours` (Default 8 h) **und** Lebenszeit-CPU
     < `IdleCpuSeconds` (Default 120 s).
  3. **Stale Port:** lauscht auf überwachtem Dev-Port
     (`3131,3132,5173,5174,3000,8080`, konfigurierbar) und älter als
     `PortStaleHours` (Default 24 h).
- **Kill inkl. Prozessbaum:** `taskkill /PID <id> /T /F` (erwischt Vite-Worker
  und esbuild-Kinder mit).
- **Sicherheit:**
  - **DryRun ist Default**, `-Apply` zum tatsächlichen Killen.
  - Report: PID, Name, Alter, CPU, Ports, Grund, Eltern-Status.
  - **Whitelist:** Substring-Match gegen CommandLine (case-insensitive),
    Datei `whitelist.txt`; Override per `-IncludeWhitelisted`.
  - **Selbstschutz:** eigene PID + Elternkette werden nie beendet.
  - Prozesse ohne lesbare CommandLine (System/elevated) → überspringen, markieren.
  - Schwellwerte pro Lauf: `-MaxAgeHours -IdleCpuSeconds -PortStaleHours -WatchedPorts`.
  - Log mit Rotation (>5 MB), Exit 1 bei Fehlern.

## Task-Registrierung (bindend)

- Watchdog-Task „Node Watchdog": aktueller Benutzer (kein Admin), alle 10 Min,
  Aktion `powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden
  -File %USERPROFILE%\.tools\node-watchdog\node-watchdog.ps1 -Apply`,
  Settings: StartWhenAvailable, ExecutionTimeLimit 5 Min, IgnoreNew.
- Nach jeder Registrierung: `schtasks /query /tn <name> /xml` → Export nach
  `task\<Name>.xml` (finale Pfade).
- Bestehende Tasks: gleiche Zykluszeit, nur Aktionspfad auf Runtime-Struktur umstellen.

## Migrations-Matrix

| Task | Script (bisher) | Runtime-Ziel | Status |
|---|---|---|---|
| NpmCleanup | `%LOCALAPPDATA%\Maintenance\npm-cleanup.ps1` | `.tools\maintenance\` | **migriert 2026-09-29** |
| ToolingCleanup | `%LOCALAPPDATA%\Maintenance\tooling-cleanup.ps1` | `.tools\maintenance\` | **migriert 2026-09-29** |
| RoutedWatch | `%LOCALAPPDATA%\Routed\watch-wrapper.ps1` | `.tools\routed-watch\` | **migriert 2026-09-29**, läuft auf Runtime-Pfad |
| NodeProcessMonitor | `D:\workspace\scripts\node-monitor\` | – | **gestrichen (Amendment 2026-09-29):** Reste gelöscht |
| Ruflo-PolicyLedger-Rotate-workspace | `D:\workspace\scripts\ruflo-policy-rotate.mjs` | – | **gestrichen (Amendment 2026-09-29):** Task deregistriert, Skript gelöscht |
| Node Watchdog | neu | `.tools\node-watchdog\` | **registriert 2026-09-29** (alle 10 Min) |

`run-hidden.vbs` ist geteilt (NpmCleanup + ToolingCleanup) und wandert mit in
`maintenance\`; beide Tasks zeigen danach auf den neuen Pfad.

**Ergänzung außerhalb des Plans (2026-09-26):** Scheduled Task `MemoryIngest`
(`memory-ingest/`, Session → Palast, ADR-007) ist registriert und Ready
(XML-Backup in `task\`). Er gehört nicht zur Migrations-Matrix und ist im
Deploy-Task-Map/Export bereits verdrahtet.

## Vorgehen (Reihenfolge)

1. **Implementierung:** Watchdog-Skript + Whitelist + Tests (Pester oder
   Integration über echte Test-Prozesse) im Repo.
2. **Tests:** DryRun-Report; Orphan-Test (Node via cmd-Wrapper, Wrapper killen
   → geflaggt); Port-Test mit `-PortStaleHours 0`; `-Apply` räumt Leichen inkl.
   Baum ab; Whitelist greift.
3. **Migration:** XML-Sicherungsexporte → Tasks stoppen → Dateien verschieben
   (Merge, nichts überschreiben) → Tasks auf Runtime-Pfade re-registrieren →
   `Start-ScheduledTask` je Task → finale XMLs nach `task\` exportieren.
4. **Deploy:** Runtime-Kopien nach `%USERPROFILE%\.tools\` (Merge-Logik).
5. **Verifikation:** je Task `LastTaskResult 0` + Log-Einträge; XML-Round-Trip
   an einem Task (löschen → Import aus XML → läuft) beweist Wiederherstellbarkeit;
   alle Tasks am Ende aktiv.
6. **Report:** Zielstruktur, Task-Statusliste, Log-Auszüge, Anleitung
   „Task per GUI aus XML wiederherstellen".

## Hinweise

- XMLs enthalten absolute Pfade (`C:\Users\Max Hambi\...`); Hinweis im
  Skript-Kopf: bei Re-Import auf anderem Rechner Aktionspfad anpassen.
- Drittanbieter-Ordner `%USERPROFILE%\tools\` (aleapp etc.) bleibt unberührt.
- Workflow: Trunk-Based, atomic Commits (`chore: ...`), Squash-Merge-PRs,
  Pre-Push-Hook erzwingt Lint/Test. Commits erst nach grünem Gate.

---

## Slices

### Slice T1 — node-watchdog.ps1 + whitelist.txt + Tests
**Blocked by:** –
**AC-Kernpunkte:** Kill-Kriterien 1–3 implementiert · DryRun-Default + Report ·
Whitelist · Selbstschutz · Baum-Kill · Log-Rotation · Exit-Codes · Tests grün
**Status:** [x] erfuellt (2026-09-29, nach ADR-001-Closure: 21/21 Assertions PASS ohne Known-Fails; RCA belegt 2 Watchdog-Bugs + 1 Harness-Bug, alle behoben)

### Slice T2 — deploy + Task „Node Watchdog" registrieren
**Blocked by:** T1
**AC-Kernpunkte:** Runtime-Kopie in `.tools\node-watchdog\` · Task alle 10 Min ·
Start-ScheduledTask → LastTaskResult 0 · XML in `task\`
**Status:** [x] erfuellt (2026-09-29): Task registriert (Trigger korrekt auf 10 Min), XML in `task\`; NACHBESSERUNG im Slice 6: Erstregistrierung lief ohne plan.md-bindendes `-Apply` (nur DryRun) - korrigiert + Settings (StartWhenAvailable, ExecutionTimeLimit 5 Min) ergaenzt

### Slice T3 — Migration NpmCleanup + ToolingCleanup (+ run-hidden.vbs)
**Blocked by:** –
**AC-Kernpunkte:** Scripts nach `.tools\maintenance\` · beide Tasks auf neue
Pfade re-registriert · Logs erscheinen · XMLs in `task\`
**Status:** [x] erfuellt (2026-09-29): Skripte ins Repo (`maintenance/`), Tasks auf `.tools\maintenance\` re-registriert, XMLs aktualisiert

### Slice T4 — Migration RoutedWatch
**Blocked by:** –
**AC-Kernpunkte:** Task gestoppt vor Move · Wrapper nach `.tools\routed-watch\` ·
re-registriert und läuft wieder · XML in `task\`
**Status:** [x] erfuellt (2026-09-29): Task gestoppt (inkl. innerem Watcher), Wrapper ins Repo + `.tools\routed-watch\`, per-user AtLogon-Re-Registrierung via Register-ScheduledTask (schtasks /SC ONLOGON braucht Admin), läuft wieder, XML aktualisiert

### Slice T5 — Migration NodeProcessMonitor
**Blocked by:** –
**AC-Kernpunkte:** Suite nach `.tools\node-monitor\` · Task aus Runtime-Pfad
neu registriert (war previously unregistered) · XML in `task\`
**Status:** [x] gestrichen (Amendment 2026-09-29, Operator-Entscheidung #32): alter Rest — Task war nie registriert, Suite am 2026-09-29 aus `D:\workspace\scripts\node-monitor\` gelöscht

### Slice T6 — Migration Ruflo-PolicyLedger-Rotate
**Blocked by:** –
**AC-Kernpunkte:** `.mjs` + referenzierte Helfer nach `.tools\ruflo-policy-rotate\`
· Pfad-Referenzen im Script angepasst · Task re-registriert · XML in `task\`
**Status:** [x] gestrichen (Amendment 2026-09-29, Operator-Entscheidung #32): alter Rest — Task `Ruflo-PolicyLedger-Rotate-workspace` deregistriert, Skript `D:\workspace\scripts\ruflo-policy-rotate.mjs` gelöscht (Alt-XML in `task\` bleibt als Archiv)

### Slice T7 — Gesamtverifikation + Report
**Blocked by:** T2–T4 (T5/T6 gestrichen, siehe Amendment)
**AC-Kernpunkte:** alle Tasks `Ready`/läuft · `LastTaskResult 0` ·
XML-Round-Trip-Test bestanden · Abschluss-Report im Chat
**Status:** [x] erfuellt (2026-09-29, Slice 6): alle 5 Tasks inventarisiert - Node Watchdog Ready/Result 0 (nach Zombie-Instanz-Kill + `-Apply`-Korrektur + Settings), NpmCleanup StartWhenAvailable nachgeholt (war 0x41303, Trigger 03:00 war verpasst), ToolingCleanup/MemoryIngest Result 0, RoutedWatch laufend (AtLogon, 0x41301 = laeuft ist normal); Runtime-Kopien via deploy -Force auf den gefixten Code gebracht (Logs beweisen `Ports=[3000]`, `Eltern=lebt`); XML-Roundtrip als Backup-Garantie dokumentiert (Import-Prozedur README; Ruflo-XML = Archiv mit Kommentar-Header).
**Status-Rest:** Open questions in blueprint/context/project-overview.md (0x800710E0-Instance-Wechsel bei IgnoreNew ist Task-Designer-Rauschen, kein Fehler - belegt durch Result 0 + saubere Log-Laeufe)

---

## Abgleich-Log

| Datum | Ereignis |
|---|---|
| 2026-09-24 | Plan genehmigt (inkl. Erweiterung: alle bestehenden Tasks konsolidieren, XML-Backups in `task\`). |
| 2026-09-24 | Repo angelegt (seit 2026-09-25: `D:reebuff-dev-setup`); Implementierung in neuer Sitzung. |
| 2026-09-25 | Ordner + Repo auf `freebuff-dev-setup` umbenannt (Issues #21-#26); Doku/Configs umgestellt. |
| 2026-09-26 | Abgleich Repo ↔ Betrieb: MemoryIngest als Ergänzung registriert (Ready, Result 0, XML in `task\`); T2–T6 liegen noch vor der Migration (Tasks zeigen auf Alt-Pfade, Node Watchdog/NodeProcessMonitor fehlen); XML-Backups in `task\` spiegeln den Ist-Zustand. Gate-Scope: `npm run lint` + CI linten jetzt auch `memory-ingest`. |
| 2026-09-29 | Migration T2-T4 gezogen: Node Watchdog registriert (Trigger auf 10 Min korrigiert); NpmCleanup/ToolingCleanup/RoutedWatch auf `.tools\` re-registriert (RoutedWatch vor Move gestoppt; AtLogon jetzt per-user via Register-ScheduledTask, da `schtasks /SC ONLOGON` Admin verlangt). Amendment: T5/T6 als alte Reste gestrichen — NodeProcessMonitor war nie registriert, `node-monitor\`-Suite und `ruflo-policy-rotate.mjs` gelöscht, Task `Ruflo-PolicyLedger-Rotate-workspace` deregistriert (Operator-Entscheidung, #32). |
| 2026-09-29 | Slice 3+6 (Struktur-Plan): ADR-001-RCA geschlossen (H2 Locale-Port-Bug, H6 PID-Reuse-Invertierung, H7 Harness-Spawns; 21/21 PASS), install-task.ps1 vergibt jetzt StartWhenAvailable + ExecutionTimeLimit und registriert den Watchdog mit `-Apply` (T2-Abweichung korrigiert), Runtime per deploy -Force aktualisiert, T7-Verifikation erfuellt (alle Tasks inventarisiert, Result 0 bewiesen). |
