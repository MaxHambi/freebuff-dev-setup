# #32: Slice T2-T6: Task-Migration nie gezogen (Alt-Tasks laufen auf urspruenglichen Pfaden)

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#32](https://github.com/MaxHambi/freebuff-dev-setup/issues/32).
> Label: `ready-for-human`. Status offen.

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

- [ ] Entscheidung: Migration T2-T6 ziehen oder Plan offiziell anpassen/schrumpfen
- [ ] T2: Node Watchdog registrieren (alle 10 Min, Runtime-Pfad, -Apply) + XML
- [ ] T3: NpmCleanup + ToolingCleanup (+ run-hidden.vbs) nach .tools\maintenance\, re-registrieren + XML
- [ ] T4: RoutedWatch stoppen, Wrapper nach .tools\routed-watch\, re-registrieren + XML
- [ ] T5: NodeProcessMonitor nach .tools\node-monitor\, neu registrieren + XML
- [ ] T6: ruflo-policy-rotate.mjs (+ Helfer) nach .tools\ruflo-policy-rotate\, Pfad-Referenzen anpassen, re-registrieren + XML
- [ ] T7: Gesamtverifikation (LastTaskResult 0 je Task, XML-Round-Trip-Test) + plan.md-Slices auf [x]

## Referenzen

- plan.md (Abgleich-Log 2026-09-26, Slices T1-T7)
- `npm run deploy` / `install-task.ps1 -Register` / `export-tasks.ps1` (Deploy-Pipeline)
