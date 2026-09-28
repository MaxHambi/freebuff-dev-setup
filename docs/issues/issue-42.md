# #42: Slice 6: Pester-Suite + PSScriptAnalyzer im Verify-Gate

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#42](https://github.com/MaxHambi/freebuff-dev-setup/issues/42).
> Label: `ready-for-agent`. Status offen.

## Parent

#36 (Umbrella)

## What to build

Test- und Lint-Gate: Pester-Suite (`nextdns-manager/tests/`) mit gemocktem HTTP-Seam (fixtures: 200+data, 200+errors, 400+errors, 429+Retry-After, cursor-Pages), PSScriptAnalyzer-Run ueber alle Repo-.ps1 mit `nextdns-manager/PSScriptAnalyzerSettings.psd1`, Integration in `scripts/test.ps1` und `npm run verify`. CI (ci.yml powershell-Job) greift automatisch (ubuntu+windows).

## Acceptance Criteria

- [ ] Pester-Suite laeuft auf PS 7 (lokal und CI) und deckt ab: Error-Parsing (200+errors[], 400), 429/Retry-After, Limit-Clamps, Pagination-Dedupe, Dimensions-Registry (reasons ohne type, destinations mit type), Dispatch-Tabelle, Config-Validierung
- [ ] `Invoke-ScriptAnalyzer` mit Settings-File meldet 0 Fehler ueber nextdns-manager/
- [ ] `scripts/test.ps1` fuehrt Pester + PSScriptAnalyzer aus (Exit 1 bei Fehlern), bleibt auf Nicht-Windows lauffaehig
- [ ] `npm run verify` enthaelt die neuen Schritte und bleibt gruen
- [ ] Keine Live-API-Calls in Tests (alles gemockt ueber den Seam)

## Blocked by

#37, #38, #39, #40, #41
