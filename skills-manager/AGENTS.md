Apply root AGENTS.md first, then this file.

# skills-manager – Ordner-Kontext (AGENTS.md)

- **Bun-only**: Laufzeit und Tests (`bun test`); Node ist kein Ziel (OpenTUI braucht ≥26.4).
- **OpenTUI**: Slice 2+ nutzt `@opentui/core` imperativ (`createCliRenderer`, Renderables) – keine React/Solid-Bindings; Layout kompakt (keine Paddings, information-dicht).
- **Original-Bibliothek nur lesen**: `~/.agents/skills/` wird von diesem Tool nie verändert; Schreibzugriffe nur auf `src/data/` (gitignored) und später den Mirror `~/.agents/skills-org/` (ADR-005).
- **Zwei Test-Seams** (ADR-004): Lib-Funktionen pure mit injiziertem Root → tmp-Fixtures; TUI über `testRender()`-Frames. Kein fs.watch-Timing-Test, kein echtes routed in Tests.
- **Conventional Commits + CHANGELOG**: `feat`/`fix` ohne `[Unreleased]`-Eintrag scheitern am CI-Drift-Check (`scripts/check-changelog.ts`).
- **Skripte**: `check-commits.ts`/`check-changelog.ts` sind bewusst dependency-frei (bun stdlib), damit `bunx` sie ohne Install läuft.
- **State/Migration**: `state.json`-Format nur erweitern, nie umbauen – alte States müssen weiter lesbar bleiben (Move-Erkennung hängt am Hash).
- Doku-Einstieg: `docs/INDEX.md`; Issue-Map mit Dependencies in `docs/PROCESS.md`.
- **Nur AGENTS.md** (keine CLAUDE.md mehr in diesem Repo - Konvention: AGENTS.md ueberall).
