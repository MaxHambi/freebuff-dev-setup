# Plan: ready-for-human Closeout (2026-09-29, rev. 2 — genehmigt)

> Quelle: Mission-Freigabe in der Session vom 29.09.2026. Dieser Plan ist die
> Arbeitsschritt-Referenz fuer den Entwicklungsbranch
> `feat/ready-for-human-closeout` und bleibt bis zum Final-Merge unverändert
> an dieser Stelle (Aenderungen nur als eigener Commit mit Begruendung).

## Workflow-Geruest (gilt fuer alle Slices)

1. Entwicklungsbranch `feat/ready-for-human-closeout` von `master`.
2. Pro Slice **issue-first**: GitHub-Issue anlegen, Mirror unter `docs/issues/`.
3. Umsetzung mit regelmaessigen **Conventional Commits**; geaddet werden nur
   slice-zugehoerige Pfade, keine Sammel-Commits.
4. PR in den **Entwicklungsbranch**; Merge erst nach gruenem `npm run verify`.
5. Regelmaessiger Push des Branches; Status-Kommentare (alle 10–15 min) am
   jeweils aktiven Issue.
6. Ist der Branch komplett: PR `feat/...` → `master`, Operator-Review, Merge,
   Branch loeschen.
7. MemPalace: ADRs und Result-Drawer werden zusaetzlich gesichert
   (Identity `maxhambi:freebuff:freebuff-dev-setup`, Wing `freebuff_dev_setup`).

## Ausgangsbefunde (bewiesen am 2026-09-29)

- Freebuff nutzt `~/.agents/mcp.json` als Standardpfad: liest UND schreibt ihn
  (UI-Add-Button schrieb den mempalace-Block dorthin; Hash davor
  `1902aeee...`, danach `b43adf56...`).
- `~/.freebuff/mcp.json` (2091 Zeilen) ist **kein** Server-Register, sondern
  der app-interne **Attestierungs-Ledger**: pro Server `configKey, enabled,
  launchHash, manifestHash, generation, allowedTools, approvedManifest,
  credentialBindings`. Enthaelt die 5 am 24.09. 01:55 importierten Server
  (supabase disabled, rayrun/synapse/routed/claimidx enabled) — mtime-Koppelung
  beider Dateien innerhalb von 4 ms belegt den synchronen Import.
- Die Freebuff-UI hat **keine** Projekt-Ebene fuer MCP-Consent; der in #28
  urspruenglich angenommene Weg (Projekt-`.mcp.json`-Consent-Prompt) existiert
  in dieser UI-Version nicht.
- Projekt-`.mcp.json` bleibt unangetastet (ADR-009 gilt weiter) und dient als
  Dokumentation/Fallback fuer andere Harnesses.
- `check-mempalace.ps1` liefert solange Exit 2 (GELB), bis Freebuff nach dem
  Neustart mempalace importiert hat und der Operator die Freigabe erteilt hat.

## Slices (Reihenfolge verbindlich; Abhaengigkeiten in Klammern)

### Slice 0 — Branch + Plan-Datei (dieser Commit)
- [x] Branch `feat/ready-for-human-closeout` von `master`
- [x] Plan-Datei (diese Datei) + Mirror-Issue N0 + PR in den Branch

### Slice 1 — ADR-010, ADR-11, MemPalace-Uebersicht (unabhaengig)
- [ ] `docs/decisions/ADR-010-freebuff-mcp-config-pfad.md` (Beweiskette:
      configKey-Mapping, 4-ms-Mtime-Koppelung, Vorher/Nachher-Hashes,
      UI-Befund; Ledger-Rolle; Projekt-`.mcp.json` bleibt, ADR-009 weiter
      gueltig)
- [ ] `docs/decisions/ADR-011-mempalace-uebersicht-navigation.md`
      (selbstbeschreibender Palast, Navigations-Drawer „Palast-Index",
      Pflege-Regel)
- [ ] `docs/mempalace-uebersicht.md` (Wing, Rooms, Drawer-Kategorien,
      Suchbeispiele)
- [ ] AGENTS.md-Referenzzeile ausserhalb des kanonischen Shared-Brain-Blocks
- [ ] `docs/index.md` + README-Tabelle aktualisieren
- [ ] MemPalace-Drawers: ADR-010, ADR-011, „Palast-Index" (room documentation)
- [ ] Issue N1 + Mirror + PR → Merge

### Slice 2 — #28 abschliessen (haengt am Operator: Neustart + Freigabe)
- [ ] Operator: Freebuff-Neustart, Freigabe mempalace (45 Tools)
- [ ] Verifikation: Ledger-Eintrag mempalace (enabled=true, 45 allowedTools),
      `check-mempalace.ps1` Exit 0, nativer MCP-Test im frischen Thread
- [ ] Abschlusskommentar + Close; Mirror-Korrektur (realer Weg: globaler
      Pfad via UI-Add, NICHT Projekt-Consent)
- **Blockierungsregel:** Existiert der Ledger-Eintrag nicht (Exit 2), Stand an
  #28 dokumentieren und mit Slice 3 weitermachen statt zu blockieren.

### Slice 3 — Diagnose-Hinweis + #29 (nach Slice 1 moeglich)
- [ ] `memory-ingest/check-mempalace.ps1`: WARN-Text auf realen Weg umstellen
      („Server via Freebuff-UI hinzufuegen — schreibt ~/.agents/mcp.json —
      nach Neustart freigeben"), Header-Verweis auf ADR-010
- [ ] #29 re-scopen: Verifikation = Exit 0 + native `mempalace_*`-Tools im
      neuen Thread; ausfuehrbar sofort, Rest als Handoff
- [ ] Issue N2 + Mirror + `npm run verify` + PR → Merge

### Slice 4 — #31: Decision-Drawer + KG-Facts (unabhaengig, inhaltlich nach
Slice 1)
- [ ] Drawer zum #28-Befund (ADR-010-Verweis), KG-Facts: Freebuff-MCP-Config-
      Pfad, Ledger-Rolle
- [ ] Mirror + Commit + PR → Merge

### Slice 5 — #30: Room-Mapping memory_ingest (Operator tippt)
- [ ] Operator ergaenzt in `mempalace.yaml` (agentenseitig blockiert):
      `- name: memory_ingest` / `description: Files from memory-ingest/` /
      `keywords: [memory_ingest, memory-ingest]`
- [ ] Agent: `mempalace mine D:/freebuff-dev-setup` verifiziert Room-Zuordnung
- [ ] Mirror + Commit + PR → Merge

### Slice 6 — #32: Task-Migration T2–T6 (groesste Entscheidung)
- [ ] Task-Inventar erheben (Get-ScheduledTask, .tools-Inventar, XML-Abgleich,
      LastTaskResult)
- [ ] Operator-Entscheidung: Migration ziehen (T2→T6, RoutedWatch vorher
      stoppen, XML-Backup je Task, T7-Gesamtverifikation) oder Plan offiziell
      schrumpfen/anpassen
- [ ] Umsetzung je Entscheidung + Mirror + PR → Merge

### Slice 7 — optional: Denylist-Write-Roundtrip (Operator-Consent)
- [ ] `Add-Denylist` Test-Domain → `Get-Denylist` verifizieren →
      `Remove-Denylist` → Endzustand; Ergebnis an #43

### Slice 8 — Abschluss
- [ ] Housekeeping AFK-Report (`nextdns-manager/nextdns-fullreport-*.txt`
      loeschen oder ignorieren — Operator-Frage im Lauf)
- [ ] Mirror-SHA-Header finalisieren, Changelog `[Unreleased]` pflegen
- [ ] Final: `npm run verify` → PR `feat/...` → `master` → Operator-Review →
      Merge → Branch loeschen → Result-Drawer (room milestone)

## Risiken / Notizen

- Slice 2 blockiert nur sich selbst; die Blockierungsregel haelt den Fluss
  am Laufen.
- Slice 6 kann plan.md-Nachfolgearbeit triggern → eigener Slice im Branch.
- Operator-Eingriffe (mempalace.yaml, Consent-Freigabe, Migration) sind im
  Plan markiert und werden nie agentenseitig ersetzt.
- Untracked bleiben ausserhalb aller Slices:
  `.agents/skills/code-refactoring-refactor-clean/` (Operator-Herkunft) und
  das AFK-Report-Artefakt (Slice 8).
