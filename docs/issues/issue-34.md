# #34: test: project-mirror E2E (Wegwerf-Issue)
<!-- mirror-sync: source=github:MaxHambi/freebuff-dev-setup#34 sha256:25066f67905572fc255b3d7c2c21ef9da893960d4cf640def8b25a676300e734 synced=2026-09-30T03:55:47Z -->

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#34](https://github.com/MaxHambi/freebuff-dev-setup/issues/34).
> Label: `needs-triage`. Status: **geschlossen (completed)** — E2E-Test abgeschlossen.
> Closure-Kommentar: [#34 (Kommentar)](https://github.com/MaxHambi/freebuff-dev-setup/issues/34#issuecomment-3344659073)

## Original-Body

Wegwerf-Issue zum Testen von .github/workflows/project-mirror.yml.

Erwartungen:
1. Bei Anlage (dieses Event): Workflow-Run `project-mirror` erscheint und endet gruen - mit Secret unset mit ::warning:: + Skip, mit Secret mit Board-Eintrag auf Backlog.
2. Nach PAT-Setup: Label `ready-for-agent` setzen -> Item auf Ready; Label `in-review` -> In review; schliessen -> Done.

Wird nach erfolgreichem E2E geloescht (gh api -X DELETE). Nicht fuer echte Arbeit verwenden.

## Kommentare

> **MaxHambi**: E2E-Test abgeschlossen (opened-Run gruen, Skip-Guard verifiziert, Built-in Auto-Add entdeckt). Label-Spiegel-E2E folgt nach PAT-Setup; Issue wird geloescht.
