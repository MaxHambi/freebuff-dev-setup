# Plan: Struktur & Ordnung in Projekt/Repo/GitHub (2026-09-29, rev. 2 — genehmigt)

> Quelle: Operator-Auftrag in der Session vom 29.09.2026. Dieser Plan ist die
> Arbeitsschritt-Referenz und bleibt bis zum Abschluss unverändert an dieser
> Stelle (Aenderungen nur als eigener Commit mit Begruendung).
> Workflow: Issue → Issue-Comment → Branch → PR → Merge (wie bisher).
> Master-Commits sind erlaubt, wo kein Feature-Branch existiert; wo einer
> existiert (PR #59), laeuft der Closeout darueber.

## Ziel & Leitplanken

Das Repo nach der Task-Migration (#32) und der Closeout-Mission (#53–#60) in
einen sauberen, selbsterklärenden Zustand bringen — inkl. GitHub-Ebene
(Issues, ADRs, Roadmap). Alles im bewaehrten Issue-first-Workflow.

## Verifizierte Befundlage (Stand 2026-09-29, read-only)

- `mempalace.yaml` enthaelt den `memory_ingest`-Room bereits (Zeilen 51–53,
  gitignored). #30 braucht nur Re-Mine + Nachweis + Close.
- **Working Tree (dirty):** komplettes `skills-manager/` uncommittet geloescht
  (27 Dateien) + 36 ungetrackte Skill-Ordner in `.agents/skills/`.
  Operator-Entscheid: Loeschung rueckgaengig machen, Skills ausduennen.
- **ADR-001:** 4 Known-Fails im Watchdog-Harness, RCA offen (Hypothesen H1–H5,
  H4 = Test-Bug am wahrscheinlichsten). **Issue #14 ist der passende
  Tracking-Issue.**
- **Offene Issues (8):** #30 (Slice 1), #14 (Slice 3), #16, #20, #15, #19,
  #17, #6 — Schliess-/Roadmap-Entscheide in Slice 7.
- **Reststellen** der gestrichenen Alt-Tasks: README.md (deploy-/install-task-/
  export-tasks-Tabellen), `node-watchdog/whitelist.txt` (`node-monitor`),
  `task/Ruflo-PolicyLedger-Rotate-workspace.xml` (Archiv), Mirror/plan.md/
  CHANGELOG (Historie, bleibt).
- **Skript-Bestand:** `scripts/` (deploy, export-tasks, install-task,
  skill-history-log, syntaxcheck, test.ps1, hooks/pre-push), `node-watchdog/`
  (inkl. streunendem `node-watchdog.log`), `routed-watch/`, `maintenance/`.

## Schritt 0 — Plan festhalten (dieser Commit)

Diese Plan-Datei auf dem Branch `feat/ready-for-human-closeout` committen
(Praezedenz: `00269aa` — Plan-Datei fuhr mit PR mit).

## Slice-Übersicht

| # | Inhalt | Basis | Skills (Repo bevorzugt) | Gate |
|---|--------|-------|--------------------------|------|
| 1 | Closeout alte Mission: #30 verifizieren+close, PR #59 ready | `feat/ready-for-human-closeout` | `/session-docs-guardian`, git-pr-workflows | `npm run verify` |
| 2 | `.agents/skills/` ausduennen (36 untracked → 14 behalten) | master, Issue + `chore/skills-prune` | `/agents-md`, `/brainstorm` (inline) | verify + Inventory-Diff |
| 3 | 4 Known-Fails testgetrieben nach ADR-001 (H1–H5), **Issue #14** | master, `fix/watchdog-known-fails` | `/debug`, `/fix`, `/architect`+`/overhaul` (inline) | Harness 22/22 |
| 4 | Skript-Inventar: Notwendigkeit/Qualitaet/Nutzfaktor + Reststellen | master, Issue + `chore/scripts-inventory` | `/analyze-project`, `/brainstorm` (inline) | Report + verify |
| 5 | Struktur-Umsetzung: Dateien loeschen/fuehren, Doku aktualisieren | master, Issue + `chore/structure-cleanup` | `/architect`+`/overhaul` (inline), `/agents-md`, `/session-docs-guardian` | verify |
| 6 | Gesamtverifikation + plan.md-T7 | master, Issue + `chore/final-verification` | `/analyze-project` (Auswertung) | verify + Harness + T7-Report |
| 7 | GitHub-Ordnung: ADRs/Issues schliessen, loeschen, ROADMAP | master, Issue + `chore/github-cleanup` | git-pr-workflows, `/session-docs-guardian` | Roadmap-Datei + clean Issue-Liste |
| 8 | Session-Closeout: Doku, Learnings, MemPalace | master, `docs/session-closeout` | `/learn`, `/session-docs-guardian`, `/overview` | verify + sessions.md |

Reihenfolge: 1 → (2 ∥ 3) → 4 → 5 → 6 → 7 → 8. Slices 2 und 3 sind unabhaengig
und koennen parallel laufen.

## Skill-Fallback-Kette (gilt fuer alle Slices)

Repo `.agents/skills/` → User-Level `~/.agents/skills/` → **nur bei echter
Notwendigkeit** `~/.agents/skills/.disabled/` (Re-Enable wird im jeweiligen
Slice-Issue dokumentiert, nie still). `/architect`, `/learn`, `/overhaul`
liegen in keinem Ordner — sie sind Inline-Definitionen des Operators und
werden genau so angewendet. `/discovery` ist durch diesen Plan abgedeckt.

---

## Slice 1 — Closeout alte Mission (#30 + PR #59)

1. **Hygiene zuerst:** `git restore skills-manager/` (Operator-Entscheid:
   Wiederherstellen), danach `npm run verify` → muss gruen sein, bevor
   irgendetwas anderes passiert.
2. `mempalace.yaml`-Block verifiziert (3 Zeilen vorhanden). Re-Mine:
   `mempalace mine D:/freebuff-dev-setup` → Nachweis, dass `memory-ingest/*`
   in Room `memory_ingest` einsortiert wird (nicht `general`). Ausgabe-
   Ausschnitt als Beweis sichern.
3. Issue-Kommentar auf #30 mit Mine-Nachweis → **Close #30**. Mirror
   `docs/issues/issue-30.md` abhaken + SHA-Header ergaenzen.
4. CHANGELOG `[Unreleased]` ergaenzen; PR #59: Body finalisieren,
   `npm run verify`, **auf ready setzen**.
5. Merge von #59 nach `master` erst nach Operator-Review; Merge ist der
   Startpunkt fuer alle Folge-Slices.

## Slice 2 — Skills-Flood ausduennen (.agents/skills/)

1. **Keep-Liste (14, committen):** `agents-md`, `analyze-project`,
   `brainstorming`, `session-docs-guardian`, `blueprint` + git/gh/github-Set
   (`git-advanced-workflows`, `git-pr-workflows-git-workflow`,
   `git-pr-workflows-pr-enhance`, `github`, `github-actions-advanced`,
   `github-actions-templates`, `github-presence`,
   `github-workflow-automation`, `gitops-workflow`).
2. **Delete-Liste (22 Duplikate):** `agenttrace-session-audit`,
   `api-documentation-generator`, `c4-*` (5), `code-documentation-*` (2),
   `code-refactoring-refactor-clean`, `context-driven-development`,
   `docs-architect`, `fp-pragmatic`, `fp-ts-pragmatic`, `gm`, `gm-continue`,
   `idea-refine`, `observability-and-instrumentation`, `prd`,
   `security-bluebook-builder`, `source-driven-development`, `wfgy-method`.
   **Safety-Check je Ordner:** nur loeschen, wenn
   `~/.agents/skills/<name>/SKILL.md` existiert; sonst behalten und im Issue
   markieren.
3. **ADR-012 „Skills-Layout":** Repo = Blueprint-Workflow + git/gh/github-Set;
   User-Level = persoenliche Bibliothek; Fallback-Kette wie oben.
4. Issue #20 (gm-Skill-Evaluierung) Kommentar: Repo-seitige Entfernung von
   `gm`/`gm-continue` verweist auf User-Level-Bibliothek; finale
   Evaluierungs-Entscheidung bleibt in #20 (Behandlung in Slice 7).
5. README-Skills-Abschnitt + `docs/index.md` + AGENTS.md-Adapter-Notiz
   aktualisieren.
- Gate: verify gruen; `git status` zeigt danach nur die Keep-Skills als neu.

## Slice 3 — Known-Fails testgetrieben beheben (ADR-001, Issue #14)

Vorgehen exakt nach ADR-001-Entscheidungsbaum, je Hypothese ein Kommentar mit
Beweis:

1. **Instrumentierung:** Harness-Lauf mit gedumpten Kandidatenlisten,
   Elternkette via `Win32_Process ParentProcessId + CreationDate`
   mitschreiben → H1 (Sortierung/Index-Drift) pruefen.
2. **H2 (Stale-Port):** netstat-Lauf gegen Port-Server-PID abgleichen,
   Kandidatenzeile fuer `portPids[0]` manuell inspizieren.
3. **H3 (Log-Lese):** Logdatei-Existenz vor jeder Assertion erzwingen.
4. **H4 (wahrscheinlichste, Test-Bug):** Keep-Node unter ein Kill-Kriterium
   zwingen (eigener WatchedPort + `-PortStaleHours 0`), dann
   `-IncludeWhitelisted`-Listing dort verifizieren; die Fails 3+4 betreffenden
   Assertions **umbenennen/umformulieren** — Watchdog bleibt unveraendert.
5. **H5 (Keep-Node-Verwaaisung/Marker-Matching):** Kandidatenzeilen ohne
   Whitelist gegen `wd-selftest-keep`-Marker pruefen.
6. Falls H1/H2/H3/H5 einen echten Watchdog-Bug beweisen: Fix in
   `node-watchdog.ps1` (klein, testgetrieben, je Fix ein Commit).
7. **Ziel: 22/22 PASS** → ADR-001 auf **Accepted** setzen, plan.md-T1-Status-
   zeile und `docs/index.md`-ADR-Tabelle aktualisieren, Issue #14 schliessen.
   Option (nur mit Operator-Ok): Harness in `npm run verify` aufnehmen.

## Slice 4 — Skript-Inventar: Notwendigkeit, Qualitaet, Nutzfaktor + Reststellen

1. **Inventory-Bericht** (Issue-Kommentar + `docs/`-Doku) je Datei ueber
   `scripts/` (inkl. `hooks/pre-push`), `node-watchdog/`, `routed-watch/`,
   `maintenance/`:
   - **Notwendigkeit:** Referenziert von Scheduled Task, npm-Script, Hook
     oder Doku? (Beleg via grep + Task-XML-Abgleich)
   - **Qualitaet:** Syntaxcheck/Lint-Status, Header-Doku, Fehlerbehandlung,
     Exit-Codes.
   - **Nutzfaktor:** Trigger-Haeufigkeit (Task-Intervall, Deploy-Pipeline,
     Session-Hook) vs. Unterhaltungsaufwand.
   - Empfehlung je Datei: **behalten / zusammenfuehren / loeschen /
     umbenennen** — Kandidaten: `skill-history-log.ps1` (Nutzfaktor),
     `node-watchdog/node-watchdog.log` (Runtime-Artefakt, bleibt lokal),
     `run-hidden.vbs` (noch fuer beide Tasks noetig?).
2. **Reststellen-Entfernung** `ruflo-policy-rotate`/`node-monitor` (gehoren
   nicht zu diesem Projekt — vollstaendige Entfernung aus allen lebenden
   Doku-Stellen):
   - README-Zeilen (deploy-/install-task-/export-tasks-Tabellen) bereinigen;
     **Code-Check:** `scripts/deploy.ps1` und `scripts/install-task.ps1`
     spiegeln/registrieren die Alt-Ordner evtl. noch aktiv → Skripte anpassen.
   - `node-watchdog/whitelist.txt`: `node-monitor`-Eintrag entfernen.
   - `task/Ruflo-PolicyLedger-Rotate-workspace.xml`: bleibt als Archiv
     (plan.md bindend), Kommentar-Header „Archiv, Task deregistriert
     2026-09-29" — Entscheidung im Issue dokumentieren.
   - Mirror `docs/issues/issue-32.md`, plan.md-Amendment, CHANGELOG-Historie:
     **bleiben** (append-only Historie).
3. `nextdns-manager/` ist explizites Non-Goal; nur README-Strukturtabelle-
   Eintrag als eigenstaendige Komponente pruefen.

## Slice 5 — Struktur-Umsetzung + Doku-Update

1. Umsetzung der Slice-4-Matrix: Skripte loeschen/zusammenfuehren/verschieben;
   jede Aktion eigener Commit mit Begruendung.
2. **Alt-Doku pruefen/loeschen:** `docs/mempalace-audit-2026-09-26.md`
   (Befunde in ADR-007/008/010/011 aufgegangen? → loeschen oder archivieren),
   `docs/plan-2026-09-29-ready-for-human.md` (nach Merge von PR #59
   archivieren/kuerzen), Blueprint-Plaene auf Frische pruefen → bei materieller
   Aenderung `/overview` neu laufen lassen.
3. **Ueberfluessige Dateien:** `entities.json`/`mempalace.yaml` gitignored
   (lokal), `.cline/` auf Relevanz pruefen, `Mem-Palace.md` +
   `skill-history.md` bleiben (aktive Workflows), Root-`plan.md` bleibt bis
   T7 (Slice 6), dann Archiv-Entscheid.
4. **Doku-Konsolidierung:** README-Strukturtabellen, `docs/index.md` ohne
   tote Eintraege, AGENTS.md-Commands-Sektion, CHANGELOG `[Unreleased]`; jede
   Komponente hat genau einen Einstiegspunkt.

## Slice 6 — Gesamtverifikation + plan.md-T7

1. **plan.md-T7 nachholen** (einziger offener Slice der alten Mission): alle
   Tasks `Ready`/`LastTaskResult 0` (Node Watchdog, NpmCleanup,
   ToolingCleanup, RoutedWatch, MemoryIngest), XML-Round-Trip-Test an einem
   Task (loeschen → Import aus XML → laeuft) als
   Wiederherstellbarkeitsnachweis, Abschluss-Report.
2. plan.md final auf `[x]` setzen; Archiv-Entscheid (Masterplan-Referenz
   bleiben oder nach `docs/`).
3. Scheduled-Task-Eingriffe nur mit Operator-Koordination, DryRun zuerst.

## Slice 7 — GitHub-Ordnung: ADRs/Issues aufraeumen + ROADMAP

1. **ADR-Status finalisieren:** ADR-001 → Accepted (durch Slice 3; falls noch
   offen, hier nachziehen); alle anderen ADRs auf Status-Korrektheit pruefen
   (docs/index.md-Tabelle ist dafuer die Quelle).
2. **Erledigte Issues schliessen** (jeweils mit Abschlusskommentar +
   Mirror-Abhaken):
   - #14 (ADR-001-Closure) — durch Slice 3.
   - #16 (Watchdog-Reviewer-Entscheidungen) — Ueberschneidung mit #14/ADR-001:
     verbleibende Punkte abarbeiten oder als supersedt schliessen.
   - #20 (gm-Skill-Evaluierung) — nach Slice-2-Kommentar: Operator-Entscheid
     einholen (schliessen oder als User-Level-Backlog behalten).
   - #6 (TUI-Slice „Mirror-Gruppierung") — voraussichtlich obsolet durch
     ADR-006 (TUI-Eigenbau verworfen); mit Operator bestaetigen und schliessen.
3. **Issues loeschen** (Kriterium: Inhalt vollstaendig in Mirror/ADR/CHANGELOG
   gesichert UND voll gemergt oder nicht mehr benoetigt): `gh issue delete`
   je Issue erst nach Mirror-Check und Operator-Bestaetigung der
   Kandidatenliste im Slice-Issue. **Mirror-first, Delete-second.**
4. **Uebersicht offene Arbeiten:** verbleibende offene Issues ermitteln
   (#15 Routed-Index-Divergenz, #19 SkillSpector-Integration, #17
   Skills-Sync, ggf. #20, plus neue Erkenntnisse aus Slices 4/5).
5. **ROADMAP erstellen:** `docs/ROADMAP.md` — offene Arbeiten nach bester
   Reihenfolge (Abhaengigkeiten zuerst: #15 Daten-Divergenz blockiert
   routed-Vertrauen; dann #19 SkillSpector als Analyse-Quelle; #17
   Skills-Sync baut darauf auf), je Item: Ziel, Warum, Abhaengigkeiten,
   Groesse. README + `docs/index.md` verlinken die Roadmap; Roadmap wird im
   Slice-Issue zur Abnahme vorgelegt.

## Slice 8 — Session-Closeout

1. `/session-docs-guardian`: `docs/sessions.md`-Summary (inkl.
   Roadmap-Referenz), ADR-Statusberichte, CHANGELOG, README-Tabellen final.
2. `/learn` (inline): nicht-offensichtliche Learnings dieser Session in
   AGENTS.md (je 1–3 Zeilen; z. B. skills-manager-Wiederherstellung,
   Skill-Fallback-Kette, ADR-001-RCA-Ergebnis).
3. MemPalace: Result-Drawer + KG-Fakten (Skills-Layout-Entscheid ADR-012,
   Known-Fails-RCA-Ergebnis, Roadmap-Stand) — Identity
   `maxhambi:freebuff:freebuff-dev-setup`.
4. Finale Gates: `npm run verify` + Watchdog-Harness; master-Stand melden.

---

## Workflow-Geruest (gilt fuer alle Slices)

- Issue-first: GitHub-Issue (oder wiederverwendetes bestehendes) + Mirror
  `docs/issues/`, Status-Kommentare alle 10–15 min am aktiven Issue.
- Branch pro Slice von `master` (ADR-003, master-first), Conventional Commits,
  nur slice-zugehoerige Pfade stagen (nie `git add -A`).
- Merge erst nach gruenem `npm run verify`; Drift-Checks erzwingen Conventional
  Commits + CHANGELOG-Pflege.
- MemPalace-Pflichten pro Slice nach `docs/mempalace-regeln.md`.

## Nicht-Ziele

- Keine inhaltlichen Aenderungen an `nextdns-manager/` (eigenes Projekt, liegt
  nur im Repo).
- Kein Umbau der MemPalace-Integration, kein neues Feature, keine
  CI-Erweiterung ohne Operator-Ok.
- Historie (Mirrors, alte CHANGELOG-Eintraege) wird nie umgeschrieben;
  Issue-Loeschung nur nach Mirror-Sicherung.

## Risiken

- **PR #59 ist gross (14 Commits):** Merge erst nach Operator-Review; alle
  Folge-Slices haengen am frischen `master`.
- **H1–H5 koennten einen echten Watchdog-Bug aufdecken** → Fix vor Merge von
  Slice 3; Zeitpuffer einplanen.
- **Scheduled-Task-Eingriffe** (T7-Round-Trip) betreffen laufende Tasks → nur
  mit Operator-Koordination, DryRun zuerst.
- **Issue-Loeschung ist irreversibel** → Mirror-first-Regel +
  Operator-Bestaetigung der Kandidatenliste im Slice-Issue.
- **Harness-Tests nur auf Windows** sinnvoll; Gates entsprechend schneiden.
