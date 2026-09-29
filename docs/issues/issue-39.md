# #39: Slice 3: Read-Funktionen + Analytics-Registry + Report
<!-- mirror-sync: source=github:MaxHambi/freebuff-dev-setup#39 sha256:df8eef3bd5641b4b6910fa32c32fecebeaa1221223c0d36a15e95ec13b7898fe synced=2026-09-29T14:09:10Z -->

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#39](https://github.com/MaxHambi/freebuff-dev-setup/issues/39).
> Label: `ready-for-agent`. Status: **geschlossen (completed)** via PR #46, gemerged als `8d7e92e`.

## Parent

#36 (Umbrella)

## What to build

Read-Funktionen: Get-NextDnsProfile, Get-NextDnsProfiles (Liste), Get-NextDnsSettings, Get-NextDnsBlocklists, Get-NextDnsDenylist, Get-NextDnsAllowlist, Get-NextDnsLogs (Filter: Status, Search, Device, From/To, Raw, Sort, Limit), Get-NextDnsAnalytics (Dimensions-Registry: reasons OHNE type, destinations MIT type-Pflicht, domains mit status/root, ips, + bewahrte Dimensionen), optionale Time-Series-Unterstuetzung (;series-Flag), Report-Zerlegung (Report.ps1: Header/Sections/Summary, ohne-Logs-Modus).

Behebt Befund 2 (reasons-Mythos korrigiert) und ergaenzt domains/ips.

## Acceptance Criteria

- [ ] reasons-Dimension wird ohne type-Parameter abgerufen (Kommentar korrigiert: 400 kam historisch von gesetztem type)
- [ ] destinations erzwingt type=countries|gafam (Validierung vor dem Call)
- [ ] domains und ips sind abrufbar (inkl. status/root bei domains)
- [ ] Logs akzeptieren Status/Search/Device/From/To/Raw/Sort/Limit
- [ ] Time-Series per Flag (endpoint-Suffix ;series) abrufbar
- [ ] Full-Report laeuft mit und ohne Logs (without-logs-Modus)
- [ ] Profile-Liste und Profil-Wechsel funktionieren (aktives Profil im Config-Objekt)

## Blocked by

#38
