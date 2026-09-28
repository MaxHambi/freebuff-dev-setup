# #36: PRD/Umbrella: NextDNS-Manager - Onboarding, Refactor, Verification

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#36](https://github.com/MaxHambi/freebuff-dev-setup/issues/36).
> Label: `needs-triage`. Status: **geschlossen (completed)** - Mission abgeschlossen; alle 7 Slices gemerged (#44-#51), alle 10 PLAN.md-Befunde behoben, Reste-Vermerk (Write-Roundtrip) in #43.

## Problem Statement

Das Desktop-Script `C:\Users\Max Hambi\Desktop\nextdns-manager.ps1` (~970 Zeilen, Monolith) soll als eigenstaendiges PowerShell-Modul-Projekt `nextdns-manager/` ins Repo uebernommen werden. Die Analyse (Source of Truth: `nextdns-manager/PLAN.md`) zeigt 10 Befunde, davon 3 hohe: User-Fehler der API (`200 OK + errors[]`) werden als Erfolg gewertet, fehlendes Rate-Limit-Handling (429/Retry-After), fehlende Limit-Clamps/Dedupe bei Log-Pagination.

Source of Truth: `nextdns-manager/PLAN.md` (genehmigt 2026-09-28, im Palast gesichert).

## User Stories

1. Als Operator fuehre ich das NextDNS-Management ueber ein Modul mit CLI- und Menue-Modus aus, statt ein Monolith-Script.
2. Als Operator sehe ich API-User-Fehler (`200 OK + errors[]`) als Fehler an, nicht als Erfolg.
3. Als Operator wird ein 429 mit Retry-After respektiert statt fix 1 s zu warten.
4. Als Operator kann ich Logs filtern (status, search, device, from/to, raw, sort) und Analytics-Dimensionen `domains`/`ips` abrufen.
5. Als Operator sind alle schreibenden Operationen mit `-WhatIf`/`-Confirm` geschuetzt.
6. Als Maintainer laeuft Pester (gemockte API) und PSScriptAnalyzer im Verify-Gate.
7. Als Maintainer verifiziere ich das Modul per Live-Smoke gegen die echte API.

## Implementation/Testing Decisions

- Modul-Struktur (psd1/psm1 + src/), Secrets weiter via SecretManagement/SecretStore.
- Pester 5+-API (v6 installiert) mit gemocktem HTTP-Seam, keine Live-Calls in Tests.
- PSScriptAnalyzer mit repo-eigenem Settings-File; Integration in `scripts/test.ps1` + `npm run verify`.
- Module-Entscheidungen mit Begruendung in PLAN.md Abschnitt 4 (PSFramework, InvokeBuild, TUI-Module, PSRest abgelehnt).

## Out of Scope

- Streaming-Watcher (`/logs/stream`, SSE) - eigener Folge-Issue bei Bedarf.
- Scheduled Task fuer automatische Reports.
- Aenderungen an Skills-Manager-/Watchdog-Modulen.

## Slices

- #37 Onboarding (Blocker fuer alles)
- #38 Core (blocked by #37)
- #39 Read+Analytics (blocked by #38)
- #40 Write-Safety (blocked by #39)
- #41 TUI+CLI (blocked by #38)
- #42 Tests+PSScriptAnalyzer (blocked by #37-#41)
- #43 Doku+Final-Smoke (blocked by #37-#42)
