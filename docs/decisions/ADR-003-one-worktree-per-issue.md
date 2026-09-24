# ADR-003: Worktree-Strategie - Master-first, Worktree pro Task

## Status

Accepted

## Date

2026-09-24

## Context

Waehrend der Parallel-Sitzungs-Phase (Skills-Manager-Sitzung, using-skills-Sitzung, node-watchdog-Slice T1) liefen drei Worktrees unter `.worktrees/` plus der Haupt-Checkout. Das fuehrte zu:

- Merge-Konflikten zwischen den Sitzungen (README, CHANGELOG, .gitignore - dreimal manuell vereint)
- Einem verlorenen Merge-Zustand im Haupt-Checkout, der eine andere Sitzung haette blockieren koennen
- Unklarem Ownership: Skript-Ablage der einen Sitzung landete in `.freebuff/skill-extensions/`, eine andere Sitzung tippte auf dieselben Repo-Dateien
- Der verbindlichen Vorgabe: Am Ende soll **genau ein** Worktree (der Haupt-Checkout) uebrig bleiben

Gleichzeitig zeigte die Isolation auch ihren Wert: Jede Sitzung konnte ohne Ruecksicht committen und pushen (PR #12, #13, #11), waehrend master stabil blieb.

## Decision

1. **Default ist der Haupt-Checkout.** Arbeitet nur eine Sitzung an einem Thema, gibt es keinen Worktree.
2. **Ein Worktree pro Task, nur wenn isoliert gearbeitet werden muss** (zwei Sessions an einem Repo gleichzeitig, oder Experimente, die master nicht beruehren duerfen). Namensschema: `.worktrees/<topic>`, Branch `feature/<topic>`.
3. **Nach Task-Abschluss wird der Worktree sofort entfernt** (`git worktree remove`). Unerledigte Arbeit lebt als GitHub-Issue weiter, nicht als verwaister Worktree oder uncommitted Zustand.
4. **Issue-first:** Bevor ein neuer Worktree entsteht, existiert ein Issue mit Akzeptanzkriterien. Ggf. wird fuer grosse Issues ein frischer Worktree aufgemacht und danach wieder entfernt.
5. `.freebuff/` ist Sitzungs-Scratch-Space (gitignored) und gilt **nie** als Quell der Wahrheit - Branch und Issues sind das.

## Alternatives Considered

### Dauerhafte Worktrees pro laufendem Thema
- Pros: Zustand bleibt zwischen Sitzungen erhalten, kein Kontext-Reload
- Cons: Veraltete Branches, gestaute Konflikte, genau die Chaoslage dieser Phase
- Rejected: Der Bestand muss nach jedem Task zusammenfuehren sein

### Alles direkt im Haupt-Checkout, nie Worktrees
- Pros: Kein Merge-Aufwand
- Cons: Parallele Sitzungen blockieren sich gegenseitig (git index, build-Artefakte, laufende Dev-Server)
- Rejected: Fuer Multi-Sitzung ist Isolation noetig - nur eben temporär

### Long-running feature branches ohne Worktree
- Pros: Kein Plattenplatz fuer Kopien
- Cons:Mehrere Sessions im gleichen Verzeichnis heisst trotzdem gegenseitige Blockade
- Rejected: Loest nicht das Grundproblem

## Consequences

- Nach Merge von PR #11, #12, #13 werden alle drei Worktrees entfernt; der Haupt-Checkout ist wieder der einzige
- Fuer offene Issues (#3-#10 Skills-Manager-Slices, #14-#17 Nachfolge-Arbeiten) wird Worktree-Bedarf jeweils neu entschieden - mehrere kleine Slices laufen im Haupt-Checkout, grosse isolierte Themen (z. B. TUI mit laufendem Dev-Prozess) bekommen temporär einen
- Merge-Konflikte sind einmalig zu erwarten, wo mehrere Sitzungen dieselben Doc-Dateien anfassen (CHANGELOG/README); der Unreleased-Abschnitt des CHANGELOGs bleibt der Vereinigungspunkt

## Related

- PR #11, #12, #13 (die drei Parallel-Sitzungen dieser Phase)
- Issue #14-#17 (Nachfolge-Arbeiten aus den Worktrees)
- `docs/agents/issue-tracker.md` (Issue-first-Werkzeug)
