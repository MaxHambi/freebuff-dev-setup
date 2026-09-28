# #37: Slice 1: Onboarding nextdns-manager als Modul-Projekt

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#37](https://github.com/MaxHambi/freebuff-dev-setup/issues/37).
> Label: `ready-for-agent`. Status: **geschlossen (completed)** via PR #44, gemerged als `a5e9c39`.

## Parent

#36 (Umbrella)

## What to build

Projektgeruest `nextdns-manager/` als PowerShell-Modul: `NextDnsManager.psd1` (Manifest, PS 7, exportierte Funktionen leer), `NextDnsManager.psm1` (dot-sourced src/*), `run.ps1` (Einstieg, CLI-Parameter folgen in #41), `setup.ps1` (Onboarding: Modul-Prereqs pruefen, Vault-Registration, Set-Secret-Aufforderung), `docs/nextdns-api.md` (API-Doku als Repo-Quelle) und `docs/README.md` (erstmal Setup + Architektur-Overview). Der Ordner enthaelt bereits `PLAN.md` + `docs/nextdns-api.md` als ungecommte Arbeitstaende - sie werden hier committet.

## Acceptance Criteria

- [ ] `Import-Module ./nextdns-manager/NextDnsManager.psd1 -Force` laeuft fehlerfrei auf PS 7.4+
- [ ] `Get-Command -Module NextDnsManager` liefert nach #38-#41 die oeffentlichen Funktionen (vorher leere Export-Liste ist ok)
- [ ] `pwsh -File nextdns-manager/setup.ps1` prueft SecretManagement/SecretStore und gibt Setup-Hinweise (Exit 0 ohne Secrets, klare Meldung wenn Vault/Secrets fehlen)
- [ ] `docs/nextdns-api.md` enthaelt die vollstaendige API-Doku (Quelle: https://nextdns.github.io/api/)
- [ ] `docs/issues/issue-36.md` bis `issue-43.md` (Mirrors) existieren, README-Index ergaenzt
- [ ] `npm run syntaxcheck` greift auf alle neuen .ps1 und bleibt gruen

## Blocked by

None - can start immediately
