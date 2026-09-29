# #21: Ordner D:\tools-entwicklung zu D:\freebuff-dev-setup umbenennen (Stop-the-world)
<!-- mirror-sync: source=github:MaxHambi/freebuff-dev-setup#21 sha256:9563fd0e94c5486600dee408a58cf0574af17fbdd07b4843e722ce42c9adf24b synced=2026-09-29T14:09:02Z -->

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#21](https://github.com/MaxHambi/freebuff-dev-setup/issues/21).
> Label: `ready-for-agent`. Status: **geschlossen (completed)** via PR #27, gemerged als `8f520f9`.
> Closure-Kommentar: [#21 (Kommentar)](https://github.com/MaxHambi/freebuff-dev-setup/issues/21#issuecomment-5859361676)

## Original-Body

## What to build

Der Projektordner `D:\tools-entwicklung` wird zu `D:\freebuff-dev-setup` umbenannt. Das ist der Grundstein für alle nachfolgenden Umbenennungs-Issues — ohne ihn zeigen alle hartcodierten Pfade ins Leere.

**Stop-the-world vor dem Rename:**
- Alle anderen Freebuff-/Claude-Threads, die aus `D:\tools-entwicklung` arbeiten, beenden (Terminal-CWDs, Editoren, laufende Watchdogs/Dev-Server prüfen).
- `git worktree list` prüfen: registrierte Worktrees liegen außerhalb des Ordners (z. B. temporäre), müssen danach ggf. `git worktree repair` erfahren.
- Fremde/uncommittete Änderungen im Ordner NICHT anfassen oder verwerfen — der Rename ändert nichts am Git-State, aber offene Handles blockieren den Rename unter Windows.
- Der ausführende Agent muss selbst zuerst aus dem Ordner wechseln (`cd /d/` oder höher), sonst ist der Rename blockiert.

## Acceptance criteria

- [ ] Kein Prozess hält mehr Handles auf `D:\tools-entwicklung` (Explorer, Terminals, Editoren geschlossen)
- [ ] Ordner umbenannt: `D:\freebuff-dev-setup` existiert, alter Pfad nicht mehr
- [ ] `git -C /d/freebuff-dev-setup status` funktioniert unverändert (gleicher Stand, keine verlorenen Changes)
- [ ] `git -C /d/freebuff-dev-setup fetch` zieht sauber von origin
- [ ] Quality-Gate smoke: `bun test` im neuen Pfad grün (25 Tests)
- [ ] Falls Worktrees existieren: `git worktree repair` ausgeführt und `git worktree list` sauber

## Blocked by

None - can start immediately.

## Closure

Umgesetzt in PR #27, gemerged als `8f520f9` (Merge-Commit-Weg laut Worktree-Fibel). Der Projektordner liegt als `D:\freebuff-dev-setup` auf OS-Ebene (git-State byte-identisch erhalten); alle nachgelagerten Pfad-Issues (#24, #25) bauten darauf auf. Stop-the-world war eingehalten. Keine Reste.
