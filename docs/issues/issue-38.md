# #38: Slice 2: Core-Schicht (Api/Auth/ErrorHandling/Pagination/Config)
<!-- mirror-sync: source=github:MaxHambi/freebuff-dev-setup#38 sha256:gone synced=2026-09-29T17:42:32Z -->

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#38](https://github.com/MaxHambi/freebuff-dev-setup/issues/38).
> Label: `ready-for-agent`. Status: **geschlossen (completed)** via PR #45, gemerged als `3a07e98`.

## Parent

#36 (Umbrella)

## What to build

Core-Schicht des Moduls: `src/Config.ps1` (typisierter Config-Satz: BaseUrl, Limits, Dimensions-Regime, OTA-Domains), `src/Auth.ps1` (SecretManagement-Load mit `-ApiKey`/`-ProfileId`-Injektion fuer Tests), `src/Api.ps1` (einheitliches Invoke-NextDnsApi mit Retry, 429 + Retry-After, Fehler-Objekt-Return), `src/ErrorHandling.ps1` (Resolve-NextDnsError: 400+errors[], 200 OK+errors[] als FEHLER, Error-Detail-Aggregation), `src/Pagination.ps1` (generische Folgeseiten-Logik mit Dedupe via Hashtabelle, Clamp-Helper).

Behebt damit die Befunde 1, 3, 4, 5, 10 aus PLAN.md.

## Acceptance Criteria

- [ ] API-Funktion liefert bei `200 OK + errors[]` ein Fehler-Objekt (nicht Erfolg)
- [ ] 429 respektiert Retry-After-Header (Fallback 2 s), Retry nur bei 5xx/429/Netzwerk
- [ ] Log-Limit wird auf 10..1000 geclamped, Analytics-Limit auf 1..500
- [ ] Pagination sammelt ueber Folgeseiten ohne Duplikate (Cursor-Wiederholung entschaeft)
- [ ] Auth akzeptiert Test-Injektion (kein SecretManagement-Zwang im Test-Pfad)
- [ ] Keine Secret-Prints in Fehler-/Debug-Ausgaben

## Blocked by

#37
