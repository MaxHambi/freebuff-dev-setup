# #68: Nacharbeit: Session-Restpunkte 2026-10-01 - Task-Alerting, agenttrace-Baseline, Co-Author-Spur
<!-- mirror-sync: source=github:MaxHambi/freebuff-dev-setup#68 sha256:be3797575e76157218a4d2e9674f03b3636431268d4e7f5fc1b4109f39b8e3f4 synced=2026-10-01T15:29:56Z -->

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#68](https://github.com/MaxHambi/freebuff-dev-setup/issues/68).
> Label: `needs-triage` + `agent:codebuff` + `ai-generated`. Status: offen
> (Session-Restpunkte der Session 2026-10-01, kein Blocker).

## Ausgangslage (verifizierte Fakten)

Die Session 2026-10-01 ist abgeschlossen und verifiziert (npm run verify
gruen, Selbstpruefung 22/22 PASS, MemoryIngest-16:30-Lauf Result 0x0):
Fenster-Flash-Fix (PR #66), Migration aller fuenf Tasks auf den
run-hidden.vbs-Wrapper (P12, ADR-014), Attribution umgestellt auf den
Trailer `AI-Assisted: Codebuff (Buffy)` (6645a8b), LF-Vertrag via
.gitattributes (a3c0ae2), agenttrace-Advisory-Gate im pre-push-Hook
(e658345). Drei Restpunkte sind bewusst offen geblieben und in
docs/sessions.md dokumentiert - dieses Issue trackt sie.

## Warum

- Task-Alerting: Telemetrie-Luecke aus der Observability-Linse - Task-Fehlschlaege sind heute nur per Hand sichtbar.
- agenttrace-Baseline: Schwellwerte (MinHealth 70) bewusst niedrig angesetzt; Schaerfen erst mit gewachsener Baseline (Skill-Empfehlung: advisory starten, dann schaerfen).
- Co-Author-Spur: Entfernen aus gepushten Commits heisst History-Rewrite + Force-Push oder GitHub Support - beides nicht ohne ausdrueckliche Operator-Freigabe.

## Checkliste

- [ ] **Task-Fail-Alerting:** taeglicher Check aller eigenen Scheduled Tasks; bei `LastTaskResult` ungleich 0 ein Warn-Event ins Windows-Anwendungslog. Task-Registrierung nach dem Wrapper-Muster (ADR-014, `install-task.ps1`), XML-Backup via `export-tasks.ps1`, README-Hook-Landkarte + CHANGELOG nachziehen.
- [ ] **agenttrace-Baseline schaerfen:** `MinHealth` (aktuell 70 in `scripts/agenttrace-audit.ps1`) anhand gesammelter Berichte anheben, Schaerfungs-Kriterien in der Hook-Landkarte dokumentieren.
- [ ] **codebuff-team-Spur entfernen (Operator-Entscheid):** Optionen fuer 9b95377/33431d3/bde62c9 bewerten (History-Rewrite + Force-Push vs. GitHub Support) und nur nach schriftlicher Freigabe ausfuehren.

## Nicht-Ziele

- Kein blockierendes Gate aus dem agenttrace-Advisory (bleibt advisory, bis der Operator schaerft).
- Kein automatisches Neuschreiben gepuschter History ohne Freigabe.

## Vorgehen

Jeder Checkliste-Punkt als eigener Branch/PR (ADR-003); bei Bedarf in
Einzel-Issues splitten und hier querverweisen. Label `needs-triage` bis
zur Bewertung, dann je Punkt `ready-for-agent` bzw. `ready-for-human`
(Co-Author-Spur ist reiner Operator-Entscheid).
