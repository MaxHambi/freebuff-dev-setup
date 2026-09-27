# #24: Doku/Configs: tools-entwicklung zu freebuff-dev-setup umbenennen

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#24](https://github.com/MaxHambi/freebuff-dev-setup/issues/24).
> Label: `ready-for-agent`. Status: **geschlossen (completed)** via PR #27, gemerged als `8f520f9`.
> Closure-Kommentar: [#24 (Kommentar)](https://github.com/MaxHambi/freebuff-dev-setup/issues/24#issuecomment-5859362188)

## Original-Body

## Parent

- #23 (Remote-URL muss zuerst stimmen)

## What to build

Alle Vorkommnisse von `tools-entwicklung` (bzw. `tools_entwicklung` in package.json-Namenskontext) in den 11 Doku-/Config-Dateien umbenennen. Ziel-Zeichenketten: Pfad `D:\tools-entwicklung` → `D:\freebuff-dev-setup`, Repo `MaxHambi/tools-entwicklung` → `MaxHambi/freebuff-dev-setup`, npm-Name `tools-entwicklung-skills-manager` → `freebuff-dev-setup-skills-manager`.

**Betroffene Dateien (Stand Inventur):**
- `AGENTS.md`, `README.md`, `plan.md`, `Mem-Palace.md`
- `docs/index.md`, `docs/worktree-fibel.md`, `docs/agents/issue-tracker.md` (enthält die Issue-Tracker-URL `MaxHambi/tools-entwicklung` — mit umbenennen!)
- `package.json` (name-Feld), `package-lock.json` (2 Stellen — folgt automatisch via `npm install --package-lock-only`, nicht manuell editieren)
- `entities.json` (MemPalace-Entity-Manifest)

**Bewusst NICHT anfassen (User-Constraint):** alles, was Claude/Claude-Code-Harness-Verweise betrifft — `CLAUDE.md` (Symlink), `~/.claude.json` project key, `~/.claude/CLAUDE.md` Rules-Block mit Identity `maxhambi:claude:*`. Diese bleiben bis zur App-Migration unverändert.

**Achtung Abschreibfehler-Quelle:** Bezeichner gemischt mit Bindestrich/Unterstrich (`tools-entwicklung` vs. `tools_entwicklung`) — beide Formen pro Fundstelle prüfen, nur die Projekt-/Pfad-Kontexte ändern, keine coincidental matches (z. B. Citations in historischen ADRs, die den alten Namen als Zitat dokumentieren → dort Kommentar `[renamed]` ergänzen statt Text umschreiben).

## Acceptance criteria

- [ ] `grep -ri "tools[-_]entwicklung" --include="*.md" --include="*.json" .` liefert 0 Treffer (außerhalb `.git/`, `node_modules/` und den bewusst ignorierten Claude-Verweisen)
- [ ] `package.json`-name ist `freebuff-dev-setup-skills-manager`, Lockfile konsistent via `npm install --package-lock-only`
- [ ] `docs/agents/issue-tracker.md` zeigt auf die neue Repo-URL
- [ ] `Mem-Palace.md` Pfad-/Identity-Referenzen aktualisiert (mit Hinweis auf den .claude-Ausschluss)
- [ ] Quality-Gate: `bun test` grün, `npx biome lint skills-manager --max-diagnostics=none` grün

## Blocked by

- #23

## Closure

Umgesetzt in PR #27, gemerged als `8f520f9`. Alle Doku-/Config-Dateien umgestellt, inklusive package-Name `freebuff-dev-setup-skills-manager` (package.json, package-lock.json, bun.lock konsistent).

Zwei bewusste Reste (im Closure-Kommentar dokumentiert):

1. `memory-ingest/export.ts` (Zeile 35) haelt den app-eigenen Freebuff-Desktop-Projektpfad `projects/tools-entwicklung-b9df0048-.../desktop-v2.db`. Dieser interne App-Ordner folgt nicht dem Workspace-/Repo-Namen und funktioniert unverändert — eine Anpassung wuerde den Datenzugriff brechen, ohne Doku-Wert zu haben.
2. `CHANGELOG.md` nennt `tools-entwicklung` im Rename-Eintrag historisch korrekt (Beschreibung des Vorher-Zustands).

`git grep -il tools-entwicklung` findet nur diese beiden Dateien.
