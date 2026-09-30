# Issue-Mirror (Repo = Quell der Wahrheit)

Diese Spiegelung folgt der Issue-Fibel: PRD-/Slice-/Issue-Bodies werden im
Repo gespiegelt, GitHub ist der Tracker. **Abweichung dokumentiert:** Die
Skills-Manager-Slices leben bewusst unter `skills-manager/docs/issues/` (ihre
Doku-Welt); dieser Ordner hier spiegelt die repo-weiten Session-Issues (Operations, MemPalace, Task-Migration, Rename) — seit 2026-09-30 auch die
Skills-Manager-Slices #2–#10 als Body-Mirrors mit mirror-sync-Header
(die Detail-Spiegel mit Implementierungsnotizen bleiben unter
`skills-manager/docs/issues/`, weiterhin ohne Header). Aktualisierungen im
Tracker werden hier nachgezogen.

**Gelöschte Issues:** Wird ein Issue auf GitHub gelöscht, bleibt der Mirror
als Quelle bestehen — sein mirror-sync-Header wird auf `sha256:gone`
gesetzt (`scripts/mirror-sync.ps1 -Update`). Der Index vermerkt die
Löschung mit Datum; der Mirror-Body dokumentiert Titel, Entscheidung und
Closure-Kommentar.

## Index

| Issue | Titel | Label | Status |
|---|---|---|---|
| #1 | PRD: Skills-Manager - Analyse, Gruppierung & OpenTUI-Installer | ready-for-agent | **gelöscht (2026-09-30)** — Mirror als Quelle: [issue-1.md](issue-1.md), `sha256:gone` |
| #2 | Slice 1: Analyse-CLI - Scan, Klassifizierung, Index & Report | ready-for-agent | **gelöscht (2026-09-30)** — Mirror als Quelle: [issue-2.md](issue-2.md), `sha256:gone` |
| #3 | Slice 2: TUI-Baum read-only - Gruppen, Navigation, Beschreibungspanel | wontfix | **gelöscht (2026-09-30)** — Mirror als Quelle: [issue-3.md](issue-3.md), `sha256:gone` |
| #4 | Slice 3: Multi-Select, Filter & Badges in der TUI | wontfix | **gelöscht (2026-09-30)** — Mirror als Quelle: [issue-4.md](issue-4.md), `sha256:gone` |
| #5 | Slice 4: Install-Flow - Pfad-Dialog, Copy-Engine, Summary | wontfix | **gelöscht (2026-09-30)** — Mirror als Quelle: [issue-5.md](issue-5.md), `sha256:gone` |
| #6 | Slice 5: Mirror-Gruppierung - Buckets, routed-Fallback, Dry-Run | ready-for-agent | **gelöscht (2026-09-30)** — Mirror als Quelle: [issue-6.md](issue-6.md), `sha256:gone` |
| #7 | Slice 6: Delta-Index - inkrementelle Analyse mit Move-Erkennung | ready-for-agent | **gelöscht (2026-09-30)** — Mirror als Quelle: [issue-7.md](issue-7.md), `sha256:gone` |
| #8 | Slice 7: Watcher & Mirror-Sync - Update-Erkennung im laufenden Betrieb | wontfix | **gelöscht (2026-09-30)** — Mirror als Quelle: [issue-8.md](issue-8.md), `sha256:gone` |
| #9 | Slice 8: Semantische Suche via routed (/) | wontfix | **gelöscht (2026-09-30)** — Mirror als Quelle: [issue-9.md](issue-9.md), `sha256:gone` |
| #10 | Slice 9: TUI-Live-Integration - Watcher-Thread, Rescan, Feinschliff | wontfix | **gelöscht (2026-09-30)** — Mirror als Quelle: [issue-10.md](issue-10.md), `sha256:gone` |
| #21 | Ordner D:\tools-entwicklung zu D:\freebuff-dev-setup umbenennen (Stop-the-world) | – | **gelöscht (2026-09-29)** — Mirror als Quelle: [issue-21.md](issue-21.md), `sha256:gone` |
| #22 | GitHub-Repo MaxHambi/tools-entwicklung zu MaxHambi/freebuff-dev-setup umbenennen | – | **gelöscht (2026-09-29)** — Mirror als Quelle: [issue-22.md](issue-22.md), `sha256:gone` |
| #23 | Git-Remote-URL auf neuen Repo-Namen umstellen | – | **gelöscht (2026-09-29)** — Mirror als Quelle: [issue-23.md](issue-23.md), `sha256:gone` |
| #24 | Doku/Configs: tools-entwicklung zu freebuff-dev-setup umbenennen | – | **gelöscht (2026-09-29)** — Mirror als Quelle: [issue-24.md](issue-24.md), `sha256:gone` |
| #25 | Skill-Extensions: 23 PS1-Skripte auf neuen Ordnerpfad umstellen | – | **gelöscht (2026-09-29)** — Mirror als Quelle: [issue-25.md](issue-25.md), `sha256:gone` |
| #26 | MemPalace: Wing tools_entwicklung zu freebuff_dev_setup umbenennen + neu minen | – | **gelöscht (2026-09-29)** — Mirror als Quelle: [issue-26.md](issue-26.md), `sha256:gone` |
| [#27](https://github.com/MaxHambi/freebuff-dev-setup/pull/27) | chore: Projekt auf freebuff-dev-setup umbenennen (#21-#26) | – | gemerged (8f520f9) |
| #28 | Freebuff-Consent fuer mempalace-MCP-Server freischalten | – | **gelöscht (2026-09-29)** — Mirror als Quelle: [issue-28.md](issue-28.md), `sha256:gone` |
| #29 | Nacharbeit: mempalace_*-Tools nach Consent live verifizieren | – | **gelöscht (2026-09-29)** — Mirror als Quelle: [issue-29.md](issue-29.md), `sha256:gone` |
| #30 | mempalace.yaml: Room-Mapping memory_ingest ergaenzen (Edit-Tool-Blockade) | – | **gelöscht (2026-09-29)** — Mirror als Quelle: [issue-30.md](issue-30.md), `sha256:gone` |
| #31 | Gedaechtnis-Ergaenzung: Memory-Ingest-Decision-Drawer + KG-Fakten | – | **gelöscht (2026-09-29)** — Mirror als Quelle: [issue-31.md](issue-31.md), `sha256:gone` |
| #32 | Slice T2-T6: Task-Migration nie gezogen | – | **gelöscht (2026-09-29)** — Mirror als Quelle: [issue-32.md](issue-32.md), `sha256:gone` |
| #34 | test: project-mirror E2E (Wegwerf-Issue) | needs-triage | **gelöscht (2026-09-30)** — Mirror als Quelle: [issue-34.md](issue-34.md), `sha256:gone` |
| #35 | test: DELETE-Reproduktion (Wegwerf) | – | **gelöscht (2026-09-30)** — Mirror als Quelle: [issue-35.md](issue-35.md), `sha256:gone` |
| #36 | PRD/Umbrella: NextDNS-Manager - Onboarding, Refactor, Verification | – | **gelöscht (2026-09-29)** — Mirror als Quelle: [issue-36.md](issue-36.md), `sha256:gone` |
| #37 | Slice 1: Onboarding nextdns-manager als Modul-Projekt | – | **gelöscht (2026-09-29)** — Mirror als Quelle: [issue-37.md](issue-37.md), `sha256:gone` |
| #38 | Slice 2: Core-Schicht (Api/Auth/ErrorHandling/Pagination/Config) | – | **gelöscht (2026-09-29)** — Mirror als Quelle: [issue-38.md](issue-38.md), `sha256:gone` |
| #39 | Slice 3: Read-Funktionen + Analytics-Registry + Report | – | **gelöscht (2026-09-29)** — Mirror als Quelle: [issue-39.md](issue-39.md), `sha256:gone` |
| #40 | Slice 4: Write-Funktionen mit WhatIf/Confirm-Schutz | – | **gelöscht (2026-09-29)** — Mirror als Quelle: [issue-40.md](issue-40.md), `sha256:gone` |
| #41 | Slice 5: TUI-Menue + CLI-Parametermodus (run.ps1) | – | **gelöscht (2026-09-29)** — Mirror als Quelle: [issue-41.md](issue-41.md), `sha256:gone` |
| #42 | Slice 6: Pester-Suite + PSScriptAnalyzer im Verify-Gate | – | **gelöscht (2026-09-29)** — Mirror als Quelle: [issue-42.md](issue-42.md), `sha256:gone` |
| #43 | Slice 7: Doku, Final-Smoke und Closures | – | **gelöscht (2026-09-29)** — Mirror als Quelle: [issue-43.md](issue-43.md), `sha256:gone` |
| #53 | Slice 0 — Plan-Basis ready-for-human-Closeout (Branch + Plan-Datei) | – | **gelöscht (2026-09-29)** — Mirror als Quelle: [issue-53.md](issue-53.md), `sha256:gone` |
| #54 | Slice 1 — ADR-010 (Freebuff-MCP-Pfad), ADR-011 (MemPalace-Übersicht) + Navigations-Drawer | – | **gelöscht (2026-09-29)** — Mirror als Quelle: [issue-54.md](issue-54.md), `sha256:gone` |
| #56 | Slice 3 — Diagnose-Hinweis auf ADR-010-Weg + #29 Re-Scope (STDIO-Verifikation) | – | **gelöscht (2026-09-29)** — Mirror als Quelle: [issue-56.md](issue-56.md), `sha256:gone` |
| [#61](https://github.com/MaxHambi/freebuff-dev-setup/issues/61) | .agents/skills ausduennen - Repo-Skills auf Blueprint-Workflow + git/gh/github-Set beschraenken (Slice 2 Struktur-Plan) | ready-for-agent | geschlossen (Closure 2026-09-29, AFK-Mission; Arbeit via PR #59 in master) |
| [#62](https://github.com/MaxHambi/freebuff-dev-setup/issues/62) | Skript-Inventar - Notwendigkeit/Qualitaet/Nutzfaktor + ruflo/node-monitor-Reststellen (Slice 4 Struktur-Plan) | ready-for-agent | geschlossen (Closure 2026-09-29, AFK-Mission; Hook-Entscheid darin dokumentiert) |
| [#63](https://github.com/MaxHambi/freebuff-dev-setup/issues/63) | audit: Implementierungs-Audit - dokumentiert vs. implementiert, Ghost-Claims geprueft (Slice 7 Struktur-Plan) | ready-for-agent | geschlossen (Closure 2026-09-29, AFK-Mission; 0 offene Ghost-Claims) |
| [#64](https://github.com/MaxHambi/freebuff-dev-setup/issues/64) | chore: GitHub-Raeumung - Issues schliessen/loeschen + ROADMAP (Slice 8 Struktur-Plan) | ready-for-agent | geschlossen (Closure 2026-09-29, AFK-Mission; 22 Loeschungen + Tombstones bewiesen) |
