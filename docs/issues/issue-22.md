# #22: GitHub-Repo MaxHambi/tools-entwicklung zu MaxHambi/freebuff-dev-setup umbenennen
<!-- mirror-sync: source=github:MaxHambi/freebuff-dev-setup#22 sha256:gone synced=2026-09-29T17:42:26Z -->

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#22](https://github.com/MaxHambi/freebuff-dev-setup/issues/22).
> Label: `ready-for-agent`. Status: **geschlossen (completed)** via PR #27, gemerged als `8f520f9`.
> Closure-Kommentar: [#22 (Kommentar)](https://github.com/MaxHambi/freebuff-dev-setup/issues/22#issuecomment-5859361830)

## Original-Body

## What to build

Das GitHub-Repo wird von `MaxHambi/tools-entwicklung` zu `MaxHambi/freebuff-dev-setup` umbenannt. GitHub leitet die alte URL automatisch weiter, aber alle lokalen/CI-Referenzen sollen sauber sein.

**Wichtig:**
- Rename über `gh repo rename freebuff-dev-setup -R MaxHambi/tools-entwicklung --yes` (oder Web-UI Settings → General → Rename).
- GitHub Pages/Releases/Issues/Stars bleiben erhalten; Weiterleitung alte→neue URL ist aktiv.
- GitHub-Topics des skill-designer-Repos sind NICHT betroffen (anderes Repo).

## Acceptance criteria

- [ ] Repo heißt `MaxHambi/freebuff-dev-setup`, `gh repo view` bestätigt
- [ ] Alte URL leitet weiter (`gh api repos/MaxHambi/tools-entwicklung` antwortet mit 301/Redirect)
- [ ] Releases (falls vorhanden) und Issues inkl. #21#22+#23 unverändert erreichbar
- [ ] Kein CI-Workflow referenziert den alten Repo-Namen hart (`.github/workflows/` prüfen)

## Blocked by

- #21 (Ordner-Rename zuerst — der lokale Checkout muss funktionieren, bevor Remote-Verweise umgebogen werden)

## Closure

Umgesetzt in PR #27, gemerged als `8f520f9`. Das Repo heisst `MaxHambi/freebuff-dev-setup`; die alte API-URL antwortet per Redirect mit dem neuen `full_name` (im PR nachgewiesen). Keine Reste.
