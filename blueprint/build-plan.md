# Build Plan — freebuff-dev-setup

> Arbeitsliste in build-Reihenfolge; abgeschlossene Items bleiben als
> Fortschritts-Tracker abgehakt. Detailed-Specs entstehen je Item via
> `/feature`. Zuletzt aktualisiert 2026-09-29.

## MVP (erledigt)

- [x] 1. **Node-Watchdog-Suite** — Kill-Kriterien 1–3, DryRun-Default,
  Whitelist, Baum-Kill, Log-Rotation; Integrationstests 21/21 PASS
  (ADR-001-Closure: Locale-Port-Mapping, PID-Reuse-Vergleich, detached
  Test-Spawns; #14).
- [x] 2. **Task-Konsolidierung T2–T4** — Node Watchdog registriert (10 min),
  NpmCleanup/ToolingCleanup/RoutedWatch auf `.tools` umgezogen, XML-Backups
  in `task/` (#32; T5/T6 als alte Reste gestrichen, Ruflo-XML = Archiv).
- [x] 3. **Memory-Ingest-Pipeline** — read-only Export, Live-Schutz,
  State-Inkrement, `ingest.ps1` als Task-Entry (ADR-007/008).
- [x] 4. **MemPalace-Integration** — nativer MCP-Pfad (ADR-010),
  Selbstbeschreibung (ADR-011), Room-Mapping `memory_ingest` (#28–#31).
- [x] 5. **Quality-Gate + Repo-Hygiene** — `npm run verify` als Pre-Push-,
  Konventions-Waechter (Claude-Bann, Mirror-Sync-Header), Skills-Layout
  ADR-012 (#61), Skript-Inventar (#62).

## Post-MVP (offen, Reihenfolge = ROADMAP)

- [ ] 6. **Routed-Index-Divergenz klaeren** — CLI `scan` (972) vs. MCP
  `scan_skills` (2843); Vertrauen in den Skills-Index wiederherstellen (#15).
- [ ] 7. **SkillSpector-Integration** — optionale Risk-Scan-Quelle in der
  Analyse-CLI (TDD, #19; haengt an 6).
- [ ] 8. **Skills-Sync automatisieren** — Anbindung + Idempotenz (#17; baut
  auf 6/7 auf).
- [ ] 9. **gm/gm-continue-Evaluierung** — Supply-Chain-Pinning,
  Konventions-Konflikte (#20; User-Level-Bibliothek, Repo-Kopien entfernt).
- [ ] 10. **Session-Doku-Hook entscheiden** — `session-end.ps1` registrieren
  oder bewusst streichen (Follow-up aus #62-Inventar).
