# #25: Skill-Extensions: 23 PS1-Skripte auf neuen Ordnerpfad umstellen
<!-- mirror-sync: source=github:MaxHambi/freebuff-dev-setup#25 sha256:280cb155f69f78ef011410c3df89be04e80c3c0553ef1c45e773caf573730c27 synced=2026-09-29T14:09:04Z -->

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#25](https://github.com/MaxHambi/freebuff-dev-setup/issues/25).
> Label: `ready-for-agent`. Status: **geschlossen (completed)** via PR #27, gemerged als `8f520f9`.
> Closure-Kommentar: [#25 (Kommentar)](https://github.com/MaxHambi/freebuff-dev-setup/issues/25#issuecomment-5859362366)

## Original-Body

## Parent

- #21 (Ordner-Rename ist Voraussetzung — sonst zeigen die Pfade ins Leere)

## What to build

Alle 23 PowerShell-Skripte in `.freebuff/skill-extensions/` enthalten hartcodierte Pfade nach `D:\tools-entwicklung`. Nach dem Ordner-Rename (#21) zeigen sie ins Leere — alle `D:\tools-entwicklung`-Strings zu `D:\freebuff-dev-setup` ändern.

**Betroffene Skripte (Stand Inventur):** add-knownfail.ps1, apply-changelog-readme.ps1, apply-i18n-triggers.ps1, apply-pending-edits.ps1, apply-pending-edits2.ps1, debug-indexes.ps1, deploy-agents-copy.ps1, fix-hook-path-resolution.ps1, fix-indent.ps1, fix-indent2.ps1, fix-indent3.ps1, fix-run-tests.ps1, fix-run-tests2.ps1, fix-run-tests3.ps1, fix-run-tests-logclear.ps1, fix-watchdog-final.ps1, fix-watchdog-opener.ps1, fix-watchdog-placeholders.ps1, fix-watchdog-precision.ps1, fix-watchdog-precision2.ps1, mark-t1-done.ps1, patch-authoring-defaults.ps1, rewrite-hooks.ps1

**Ansatz:** pro Datei per sed/PowerShell alle Vorkommnisse ersetzen (case-insensitive auf den Pfad achten), danach Syntax-Check.

## Acceptance criteria

- [ ] `grep -ri "tools.entwicklung" .freebuff/skill-extensions/` liefert 0 Treffer
- [ ] `npm run syntaxcheck` (alle Repo-PS-Skripte) grün
- [ ] Stichprobe: 2–3 der umgestellten Skripte laufen mit `-WhatIf`-Fehler (also erreichen den Datei-/Pfad-Referenz-Code ohne sofortige Crash)

## Blocked by

- #21

## Closure

Umgesetzt in PR #27, gemerged als `8f520f9`. Alle 23 PowerShell-Skripte in `.freebuff/skill-extensions/` sind auf Disk umgestellt (0 alte Pfad-Treffer, `npm run syntaxcheck` gruen, Stichproben erreichen den Pfad-Code mit dem neuen Pfad). Das Verzeichnis ist gitignored (Sitzungs-Scratch), daher nicht Teil des PR-Diffs - der Disk-Stand ist der Nachweis. Keine Reste.
