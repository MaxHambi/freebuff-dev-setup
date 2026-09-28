# NextDNS-Manager

NextDNS All-in-One Management als PowerShell-Modul. Nachfolger des
Monolith-Scripts (Historie und alle Befunde: `PLAN.md`).

## Features

- **Modul-Architektur** (PS 7.4+): 11 Submodule unter `src/`, 40 oeffentliche
  Funktionen, Implementierungsdetails privat
- **Robuste API-Schicht**: Retry nur bei Netzwerk/429/5xx,
  Retry-After wird respektiert, `200 OK + errors[]` (User-Fehler) wird
  zuverlaessig als FEHLER ausgewiesen
- **Read**: Profile, Settings, Blocklisten, Denylist, Allowlist, Logs
  (Filter: status/search/device/from/to/raw/sort), Analytics (alle
  Dimensionen inkl. domains/ips; reasons ohne type, destinations mit
  type-Pflicht), Time-Series via `;series`
- **Write**: Denylist/Allowlist add/remove (WhatIf/Confirm), Settings-PATCH,
  Clear-Logs mit ConfirmImpact=High
- **Report**: Full-Report (mit/ohne Logs), JSON-Log-Export,
  Fehler-Zusammenfassung
- **CLI + Menue**: `run.ps1 -Action <name>` non-interaktiv oder interaktives
  Menue mit Nerd-Font-Icons (JetBrainsMono/Meslo/Terminess-Erkennung,
  ASCII-Fallback)

## Setup

```powershell
# Einmalig: Prereqs pruefen, Vault anlegen, Secrets-Hinweise bekommen
pwsh -File nextdns-manager/setup.ps1

# Secrets setzen (interaktive Abfrage, nie per Kommandozeile)
Set-Secret -Name API_KEY      # NextDNS API-Key (my.nextdns.io/account)
Set-Secret -Name PROFILE_KEY  # Profil-ID (6 Zeichen, my.nextdns.io)

# Start: Menue-Modus
pwsh -File nextdns-manager/run.ps1

# Oder CLI-Modus (exit 0 = OK, 1 = API-Fehler, 2 = Konfig-Fehler)
pwsh -File nextdns-manager/run.ps1 -Action Test-Connection
pwsh -File nextdns-manager/run.ps1 -Action Get-Logs -ActionParameter @{ Limit = 50; Status = 'blocked' }
pwsh -File nextdns-manager/run.ps1 -Action Add-Denylist -ActionParameter @{ Domains = 'example.com' }
pwsh -File nextdns-manager/run.ps1 -Action Set-Profile -ActionParameter @{ ProfileId = 'abc123' }
```

CLI-Komfort-Aliase: `Get-Profiles`, `Get-Profile`, `Get-Settings`,
`Get-Blocklists`, `Get-Denylist`, `Get-Allowlist`, `Get-Logs`,
`Get-Analytics`, `Get-AllAnalytics`, `Test-Connection`, `Export-Logs`,
`Export-Report`, `Add-Denylist`, `Remove-Denylist`, `Add-Allowlist`,
`Set-Profile`, `Clear-Logs`.

## Architektur

```
NextDnsManager.psd1 / .psm1   Manifest + Loader, explizite Export-Liste
src/10-Config.ps1             Lazy Konfig-Init, Profil-Wechsel, Ready-Checks
src/15-Fonts.ps1              Nerd-Font-Erkennung + Icon-Saetze (ASCII-Fallback)
src/20-Auth.ps1               SecretManagement-Load, Injektions-Pfad fuer Tests
src/30-ErrorHandling.ps1      errors[]-Klassifikation (200+errors[] = FEHLER)
src/40-Api.ps1                Invoke-NextDnsApi + HTTP-Delegate (Test-Seam)
src/50-Pagination.ps1         Folgeseiten mit Dedupe, Limit-Clamps
src/60-Read.ps1               Get-NextDns* + Test-NextDnsConnection
src/70-Analytics.ps1          Dimensions-Registry + ;series
src/80-Write.ps1              Add-/Remove-*, Set-*, Clear-* (ShouldProcess)
src/90-Report.ps1             Full-Report-Bausteine + JSON-Exporte
src/99-Menu.ps1               Dispatch-Tabelle, Prompt-Planae, Menue-Schleife
tests/NextDnsManager.Tests.ps1  Pester-Suite (30 Tests, gemockt)
tests/smokes/ + run-smokes.ps1  Dauer-Smokes (28 Checks, 30-s-Timeout je Smoke)
docs/nextdns-api.md           API-Doku (Repo-Quelle der Wahrheit)
```

## Verifikation (4 Schichten)

`npm run verify` bzw. `pwsh -File scripts/test.ps1`:

1. Watchdog-DryRun (Windows)
2. **Pester** 30 Tests (gemockt via `Set-NextDnsHttpDelegate`, 0 Live-Calls)
3. **PSScriptAnalyzer** 0 Findings (2 Regelsaetze: Quelle + Tests, jede
   Exclusion mit Begruendung im Settings-File)
4. **Dauer-Smokes** (`tests/run-smokes.ps1`): Core, ReadAnalytics, Write,
   Menu - je Smoke eigener pwsh-Prozess mit 30-s-Haerte-Timeout (Prompts/
   Haengs brechen ab statt zu blockieren)

Live-Smoke gegen die echte API: siehe PLAN.md Abschnitt 6 (nur mit
Operator-Consent, da echte Schreibzugriffe moeglich sind).

## Exit-Codes (run.ps1 CLI-Modus)

| Code | Bedeutung |
|---|---|
| 0 | Erfolg |
| 1 | API-Fehler (Fehler-Objekt der API-Schicht) |
| 2 | Konfigurations-/Umgebungsfehler (Secrets fehlen, unbekannte Action, kein interaktiver Host im Menue-Modus) |
