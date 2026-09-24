# plan.md – Tools-Entwicklung (Tasks & Watchdogs)

> **Dauerhafte Referenz** für das Repo `D:\tools-entwicklung`.
> Der Plan wurde am 2026-09-24 genehmigt. Die **Implementierung erfolgt in einer
> neuen Sitzung** mit diesem Repo als Arbeitsverzeichnis – dieses Dokument ist
> die verbindliche Vorgabe dafür.
> Bei jedem Statuswechsel den `Status`-Block des jeweiligen Slice aktualisieren.
> Keine Tokens/Credentials in dieser Datei.

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
D:\tools-entwicklung\
├── node-watchdog\            Watchdog-Suite (Scripts, Tests, Doku)
├── node-monitor\             Migrations-Quelle: D:\workspace\scripts\node-monitor
├── maintenance\              npm-cleanup.ps1 · tooling-cleanup.ps1 · run-hidden.vbs
├── routed-watch\             watch-wrapper.ps1 (Quelle: %LOCALAPPDATA%\Routed)
├── ruflo-policy-rotate\      ruflo-policy-rotate.mjs (+ adr/, ruflo-adr-patch/ falls referenziert)
├── task\                     exportierte Task-XMLs (alle Tasks)
├── scripts\                  Deploy-/Registrierungs-Helper (install-task.ps1 etc.)
├── plan.md · AGENTS.md
```

### Runtime (Ziel nach Deploy)
```
%USERPROFILE%\.tools\
├── node-watchdog\ · node-monitor\ · maintenance\ · routed-watch\ · ruflo-policy-rotate\
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
| NpmCleanup | `%LOCALAPPDATA%\Maintenance\npm-cleanup.ps1` | `.tools\maintenance\` | registriert |
| ToolingCleanup | `%LOCALAPPDATA%\Maintenance\tooling-cleanup.ps1` | `.tools\maintenance\` | registriert |
| RoutedWatch | `%LOCALAPPDATA%\Routed\watch-wrapper.ps1` | `.tools\routed-watch\` | registriert + läuft (vor Move stoppen) |
| NodeProcessMonitor | `D:\workspace\scripts\node-monitor\` | `.tools\node-monitor\` | **nicht registriert** → neu registrieren |
| Ruflo-PolicyLedger-Rotate-workspace | `D:\workspace\scripts\ruflo-policy-rotate.mjs` | `.tools\ruflo-policy-rotate\` | registriert |
| Node Watchdog | neu | `.tools\node-watchdog\` | neu anzulegen |

`run-hidden.vbs` ist geteilt (NpmCleanup + ToolingCleanup) und wandert mit in
`maintenance\`; beide Tasks zeigen danach auf den neuen Pfad.

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
- `ruflo-policy-rotate.mjs` referenziert ggf. `scripts/adr` +
  `scripts/ruflo-adr-patch` → vor Move prüfen und Pfade im Script anpassen.
- Drittanbieter-Ordner `%USERPROFILE%\tools\` (aleapp etc.) bleibt unberührt.
- Workflow: Trunk-Based, atomic Commits (`chore: ...`), Squash-Merge-PRs,
  Pre-Push-Hook erzwingt Lint/Test. Commits erst nach grünem Gate.

---

## Slices

### Slice T1 — node-watchdog.ps1 + whitelist.txt + Tests
**Blocked by:** –
**AC-Kernpunkte:** Kill-Kriterien 1–3 implementiert · DryRun-Default + Report ·
Whitelist · Selbstschutz · Baum-Kill · Log-Rotation · Exit-Codes · Tests grün
**Status:** [ ] offen

### Slice T2 — deploy + Task „Node Watchdog" registrieren
**Blocked by:** T1
**AC-Kernpunkte:** Runtime-Kopie in `.tools\node-watchdog\` · Task alle 10 Min ·
Start-ScheduledTask → LastTaskResult 0 · XML in `task\`
**Status:** [ ] offen

### Slice T3 — Migration NpmCleanup + ToolingCleanup (+ run-hidden.vbs)
**Blocked by:** –
**AC-Kernpunkte:** Scripts nach `.tools\maintenance\` · beide Tasks auf neue
Pfade re-registriert · Logs erscheinen · XMLs in `task\`
**Status:** [ ] offen

### Slice T4 — Migration RoutedWatch
**Blocked by:** –
**AC-Kernpunkte:** Task gestoppt vor Move · Wrapper nach `.tools\routed-watch\` ·
re-registriert und läuft wieder · XML in `task\`
**Status:** [ ] offen

### Slice T5 — Migration NodeProcessMonitor
**Blocked by:** –
**AC-Kernpunkte:** Suite nach `.tools\node-monitor\` · Task aus Runtime-Pfad
neu registriert (war previously unregistered) · XML in `task\`
**Status:** [ ] offen

### Slice T6 — Migration Ruflo-PolicyLedger-Rotate
**Blocked by:** –
**AC-Kernpunkte:** `.mjs` + referenzierte Helfer nach `.tools\ruflo-policy-rotate\`
· Pfad-Referenzen im Script angepasst · Task re-registriert · XML in `task\`
**Status:** [ ] offen

### Slice T7 — Gesamtverifikation + Report
**Blocked by:** T2–T6
**AC-Kernpunkte:** alle Tasks `Ready`/läuft · `LastTaskResult 0` ·
XML-Round-Trip-Test bestanden · Abschluss-Report im Chat
**Status:** [ ] offen

---

## Abgleich-Log

| Datum | Ereignis |
|---|---|
| 2026-09-24 | Plan genehmigt (inkl. Erweiterung: alle bestehenden Tasks konsolidieren, XML-Backups in `task\`). |
| 2026-09-24 | Repo `D:\tools-entwicklung` angelegt; Implementierung in neuer Sitzung. |
