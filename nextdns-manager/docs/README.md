# NextDNS-Manager

NextDNS All-in-One Management als PowerShell-Modul. Nachfolger des
Monolith-Scripts (siehe `PLAN.md` mit allen Befunden und Entscheidungen).

## Status

| Slice | Issue | Inhalt | Stand |
|---|---|---|---|
| 1 | #37 | Modul-Geruest, Setup, API-Doku | in Arbeit |
| 2 | #38 | Core: Api/Auth/ErrorHandling/Pagination | offen |
| 3 | #39 | Read + Analytics-Registry + Report | offen |
| 4 | #40 | Write mit WhatIf/Confirm | offen |
| 5 | #41 | TUI-Menue + CLI-Modus | offen |
| 6 | #42 | Pester + PSScriptAnalyzer im Gate | offen |
| 7 | #43 | Doku, Final-Smoke, Closures | offen |

## Setup

```powershell
# Einmalig: Prereqs pruefen, Vault anlegen, Secrets-Hinweise bekommen
pwsh -File nextdns-manager/setup.ps1

# Secrets setzen (interaktive Abfrage, nie per Kommandozeile)
Set-Secret -Name API_KEY      # NextDNS API-Key (my.nextdns.io/account)
Set-Secret -Name PROFILE_KEY  # Profil-ID (6 Zeichen, my.nextdns.io)

# Start (Menue-Modus)
pwsh -File nextdns-manager/run.ps1
```

## Architektur (Zielbild, PLAN.md Abschnitt 4)

```
NextDnsManager.psd1 / .psm1   Modul-Manifest + Loader (src/*.ps1 sortiert)
src/10-Config.ps1             Typisierter Config-Satz (BaseUrl, Limits, Dimensions-Regime)
src/20-Auth.ps1               SecretManagement-Load, Test-Injektion moeglich
src/30-ErrorHandling.ps1      400+errors[], 200 OK+errors[] = FEHLER
src/40-Api.ps1                Invoke-NextDnsApi: Retry, 429 + Retry-After
src/50-Pagination.ps1         Folgeseiten + Dedupe + Limit-Clamps
src/60-Read.ps1               Get-NextDns* (Profil, Settings, Listen, Logs)
src/70-Analytics.ps1          Dimensions-Registry (reasons ohne type, destinations mit type)
src/80-Write.ps1              Add-/Remove-*, Set-*, Clear-* mit WhatIf/Confirm
src/90-Report.ps1             Full-Report (mit/ohne Logs), JSON-/CSV-Exporte
src/99-Menu.ps1               Dispatch-Tabelle + interaktives Menue
tests/                        Pester 5+-Suite mit gemocktem HTTP-Seam
docs/nextdns-api.md           API-Doku (Repo-Quelle der Wahrheit)
```

## API-Quelle der Wahrheit

`docs/nextdns-api.md` (wörtlich von https://nextdns.github.io/api/).
Wichtigste Konsequenz: `200 OK + { errors: [...] }` ist ein **Fehler**
(User-Fehler, z. B. ungültige Domain) - das Alt-Script hat das als Erfolg
gewertet (PLAN.md Befund 1).
