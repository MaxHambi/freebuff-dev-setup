# #23: Git-Remote-URL auf neuen Repo-Namen umstellen
<!-- mirror-sync: source=github:MaxHambi/freebuff-dev-setup#23 sha256:gone synced=2026-09-29T17:42:27Z -->

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#23](https://github.com/MaxHambi/freebuff-dev-setup/issues/23).
> Label: `ready-for-agent`. Status: **geschlossen (completed)** via PR #27, gemerged als `8f520f9`.
> Closure-Kommentar: [#23 (Kommentar)](https://github.com/MaxHambi/freebuff-dev-setup/issues/23#issuecomment-5859362023)

## Original-Body

## What to build

Der lokale Checkout (nach dem Ordner-Rename unter `D:\freebuff-dev-setup`) bekommt die neue Remote-URL. GitHub würde per Redirect weiterhelfen, aber explizit ist sauberer und vermeidet Verwirrung in Tools, die die URL parsen.

```bash
git -C /d/freebuff-dev-setup remote set-url origin https://github.com/MaxHambi/freebuff-dev-setup.git
```

## Acceptance criteria

- [ ] `git -C /d/freebuff-dev-setup remote -v` zeigt `.../MaxHambi/freebuff-dev-setup.git` (fetch + push)
- [ ] `git -C /d/freebuff-dev-setup fetch` erfolgreich
- [ ] `git -C /d/freebuff-dev-setup push --dry-run` erfolgreich (Schreibpfad funktioniert)
- [ ] Alle registrierten Worktrees im Repo zeigen weiterhin auf denselben origin

## Blocked by

- #22 (Repo-Rename zuerst — die Ziel-URL muss existieren)

## Closure

Umgesetzt in PR #27, gemerged als `8f520f9`. `origin` zeigt explizit auf die neue URL; der Pre-Push-Gate-Lauf beim Merge-Push ging bereits über sie (fetch + push verifiziert). Keine Reste.
