# #32: Slice T2-T6: Task-Migration nie gezogen (Alt-Tasks laufen auf urspruenglichen Pfaden)
<!-- mirror-sync: source=github:MaxHambi/freebuff-dev-setup#32 sha256:gone synced=2026-09-29T17:42:31Z -->

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#32](https://github.com/MaxHambi/freebuff-dev-setup/issues/32).
> Label: `ready-for-human`. Status: **geschlossen (completed)** 2026-09-29 — Option A auf T2-T4 gezogen, T5/T6 als alte Reste gestrichen/geloescht (Operator-Entscheidung), plan.md-Amendment im Branch.

## Ausgangslage (Abgleich 2026-09-26, belegt per Get-ScheduledTask / .tools-Inventar)

Der plan.md-Masterplan (2026-09-24 genehmigt) sieht vor, alle eigenen
Scheduled Tasks auf `%USERPROFILE%\.tools\` zu konsolidieren. Realer Zustand:

- **NpmCleanup + ToolingCleanup** - Ready, laufen aber weiterhin via
  `%LOCALAPPDATA%\Maintenance\run-hidden.vbs` auf `%LOCALAPPDATA%\Maintenance\` (T3 nie gezogen)
- **RoutedWatch** - Ready, Wrapper weiterhin `%LOCALAPPDATA%\Routed\watch-wrapper.ps1` (T4 nie gezogen)
- **Ruflo-PolicyLedger-Rotate-workspace** - Ready, laeuft weiterhin auf
  `D:\workspace\scripts\ruflo-policy-rotate.mjs` (T6 nie gezogen)
- **Node Watchdog** - Task existiert NICHT (T2 offen); Runtime-Kopie liegt
  zwar in `.tools\node-watchdog\`
- **NodeProcessMonitor** - weder Task noch Runtime-Kopie (T5 unveraendert)
- **MemoryIngest** - als Ergaenzung ausserhalb des Plans bereits auf
  Zielpfad registriert (Ready, Result 0, XML-Backup vorhanden)
- Die XML-Backups in `task\` spiegeln die Alt-Zustaende (keine Runtime-Pfade)

## Warum menschliche Umsetzung

Re-Registrierung stoppt und ueberschreibt laufende Tasks (RoutedWatch vor
Move stoppen laut Plan); die Entscheidung, ob die Migration ueberhaupt noch
gezogen werden soll, liegt beim Operator.

## Checkliste (Reihenfolge laut plan.md)

- [x] Entscheidung: Migration T2-T6 ziehen oder Plan offiziell anpassen/schrumpfen — **Amendment 2026-09-29: T2-T4 ziehen, T5/T6 streichen + Reste loeschen**
- [x] T2: Node Watchdog registrieren (Trigger korrekt auf 10 Min gefixt, Runtime-Pfad, -Apply) + XML — erster Lauf LastResult 0
- [x] T3: NpmCleanup + ToolingCleanup (+ run-hidden.vbs) nach .tools\maintenance\, re-registrieren + XML
- [x] T4: RoutedWatch stoppen (inkl. innerem Watcher), Wrapper nach .tools\routed-watch\, per-user AtLogon-Re-Registrierung via Register-ScheduledTask (schtasks /SC ONLOGON braucht Admin), re-registrieren + XML
- [x] T5: **gestrichen (Amendment)** — NodeProcessMonitor war nie registriert; Suite `D:\workspace\scripts\node-monitor\` geloescht
- [x] T6: **gestrichen (Amendment)** — Task deregistriert, `D:\workspace\scripts\ruflo-policy-rotate.mjs` geloescht (Skript waere nach `.tools` ohnehin zerbrochen: WORKSPACE_ROOT ist relativ zum Skriptpfad)
- [x] T7: Gesamtverifikation (alle 5 Tasks Ready/Running mit LastResult 0 bzw. laufend, XML-Round-Trip an NpmCleanup bewiesen) + plan.md-Slices auf [x]

## Referenzen

- plan.md (Abgleich-Log 2026-09-26, Slices T1-T7)
- `npm run deploy` / `install-task.ps1 -Register` / `export-tasks.ps1` (Deploy-Pipeline)
