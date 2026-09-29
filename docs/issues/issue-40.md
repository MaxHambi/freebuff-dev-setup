# #40: Slice 4: Write-Funktionen mit WhatIf/Confirm-Schutz
<!-- mirror-sync: source=github:MaxHambi/freebuff-dev-setup#40 sha256:f11eff2483f32e6afdb33c50e8acb25697f0f8067a3561c62e1f658d1a345c91 synced=2026-09-29T14:09:11Z -->

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#40](https://github.com/MaxHambi/freebuff-dev-setup/issues/40).
> Label: `ready-for-agent`. Status: **geschlossen (completed)** via PR #47, gemerged als `7814a0d`.

## Parent

#36 (Umbrella)

## What to build

Write-Funktionen mit Safety: Add-/Remove-NextDnsDenylist/Allowlist (POST/DELETE), Set-NextDnsSettings (PATCH auf settings/* inkl. blockPage/performance/logs), Clear-NextDnsLogs (DELETE /logs) - alle mit SupportsShouldProcess (-WhatIf/-Confirm), Batch-Handling fuer Domains, errors[]-Pfad aus #38 wird konsequent ausgewertet (User-Fehler = Fehler-Objekt pro Domain).

## Acceptance Criteria

- [ ] Alle Write-Funktionen tragen SupportsShouldProcess und respektieren -WhatIf (kein HTTP-Call bei WhatIf)
- [ ] -Confirm promptet vor DELETE-Operationen (Clear-NextDnsLogs mit ConfirmImpact=High)
- [ ] Ungueltige Domain in Denylist erzeugt pro Domain ein Fehler-Objekt (kein stiller Erfolg)
- [ ] Settings-PATCH validiert bekannte Settings-Pfade und liefert Fehler-Objekt bei 400
- [ ] Remove-Funktionen nutzen DELETE am Child-Endpoint (erste Key = id)

## Blocked by

#39
