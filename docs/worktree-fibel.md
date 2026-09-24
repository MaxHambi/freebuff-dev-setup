# Worktree-Fibel

Kurzguide passend zu [ADR-003](decisions/ADR-003-one-worktree-per-issue.md).
Frage der Fibel: Wann ist ein Worktree nötig, wie heißt er, wann stirbt er?

## 1. Wann wird ein Worktree angelegt?

Default ist **immer der Haupt-Checkout** (`D:/tools-entwicklung` auf `master`).
Ein Worktree unter `.worktrees/<topic>` wird nur angelegt, wenn **mindestens
eines** davon zutrifft:

| Bedingung | Beispiel |
|-----------|----------|
| Eine zweite Sitzung arbeitet parallel am Repo | Skills-Manager-Sitzung + Watchdog-Sitzung |
| Ein lang laufender Dev-/Watch-Prozess würde den Haupt-Checkout blockieren | OpenTUI-Entwicklung mit laufendem `bun run` + Datei-Watchern |
| Experimenteller Zweig, der `master` nicht berühren darf | POC mit Build-Artefakten |

**Nicht nötig** bei: einzelnen kleinen Slices, reinen Doku-Änderungen, Tests,
die nur `bun test` / `npm run lint` brauchen. Die laufen im Haupt-Checkout.

## 2. Voraussetzungen (Checkliste vor dem Anlegen)

- [ ] **Issue existiert** mit Akzeptanzkriterien (Issue-first, ADR-003 Regel 4)
- [ ] Branch-Name festgelegt: `feature/<topic>` (auch `fix/*`, `chore/*` – gleiches Schema)
- [ ] Der Skills-Ordner wird nicht direkt angefasst (ADR-005: Mirror statt Move)

## 3. Anlegen (2 Befehle)

```bash
# Worktree + Branch in einem Schritt
git worktree add .worktrees/<topic> -b feature/<topic>

# Dependencies im Worktree installieren (npm und bun halten getrennte Stores)
cd .worktrees/<topic> && npm ci --no-fund --no-audit && bun install
```

Optional direkt auf den aktuellen master bringen, wenn zwischenzeitlich
gemerged wurde:

```bash
cd .worktrees/<topic> && git merge master --no-edit
```

## 4. Benennung (fixes Schema)

| Objekt | Muster | Beispiel |
|--------|--------|----------|
| Verzeichnis | `.worktrees/<topic>` | `.worktrees/skills-manager` |
| Branch | `feature/<topic>` | `feature/skills-manager` |
| Topic | kurz, thematisch, englische oder deutsche Begriffe ok | `node-watchdog`, `using-skills` |

**Ein Branch = ein Thema.** Kein Misch-Worktree ("mal schnell auch noch …").

## 5. Arbeit im Worktree (Standards)

- Conventional Commits, atomar (~100 Zeilen), Attribution-Footer (siehe AGENTS.md)
- `Refs #<issue>` im Body, `Closes #<issue>` nur im PR-Body
- Vor jedem Push läuft das Pre-Push-Gate (`scripts/hooks/pre-push`):
  Lint + PowerShell-Syntaxcheck + Tests. Es muss grün sein, sonst Push verweigert
- Bei parallelen Sitzungen: **andere Sitzungen nicht anfassen** – auch nicht
  deren `.freebuff/skill-extensions/`-Ablagen (Sitzungs-Scratch, nie Quell der Wahrheit)

## 6. Merge-Weg (PR-Sequenz)

1. `git push -u origin feature/<topic>` (Pre-Push-Gate läuft lokal)
2. `gh pr create --base master` mit vollständiger Description
   (Summary, Testing, Review Checklist, Risk Assessment) und `Closes #<issue>`
3. CI abwarten (alle Checks grün), dann **Squash-Merge** für kleine Slices,
   Merge-Commit bei mehrschichtigen Verläufen
4. Der Merge erzeugt neue master-Commits → **andere offene PRs direkt
   hinterher rebasen/mergen**, bevor GitHub `CONFLICTING` meldet

Konflikt-Notfall (README/CHANGELOG/.gitignore sind beliebte Schnittmengen):
lokal `git merge master --no-edit` im Worktree, Konflikte so lösen, dass
beide Seiten erhalten bleiben, Quality-Gate laufen lassen, dann Push + Merge.

## 7. Entfernen (nach jedem Merge, sofort)

```bash
git worktree remove .worktrees/<topic> --force   # --force auch bei untracked Artefakten
git branch -d feature/<topic>                    # lokal
git push origin --delete feature/<topic>         # remote (falls nicht automatisch)
git worktree prune                               # Referenzen aufräumen
```

Danach `master` im Haupt-Checkout aktualisieren (`git pull --ff-only`) –
der Haupt-Checkout ist wieder die einzige Arbeitskopie.

## 8. Regeln im Schnelldurchlauf

1. Issue zuerst, Worktree danach
2. `.worktrees/<topic>` + `feature/<topic>`, ein Thema pro Worktree
3. Master nach dem Anlegen mergen, wenn er weitergelaufen ist
4. Nach dem Merge: Worktree **sofort** entfernen, Branch löschen
5. Unerledigte Arbeit wandert in Issues – **nicht** in verwaiste Worktrees
6. `.freebuff/` und generierte Daten (`src/data/` etc.) sind nie Quell der Wahrheit

## 9. Zustandscheck (ein Befehl je Frage)

| Frage | Befehl |
|-------|--------|
| Welche Worktrees existieren? | `git worktree list` |
| Ist einer davon schmutzig? | `git -C .worktrees/<topic> status --short` |
| Welcher Branch divergiert von master? | `git log master..feature/<topic> --oneline` |
| Sind beide merge-bar? | `git merge-tree --write-tree master feature/<topic>` (exit 0 = clean) |
