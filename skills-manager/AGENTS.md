Apply root AGENTS.md first, then this file.

# skills-manager – Ordner-Kontext (AGENTS.md)

- **Bun-only**: Laufzeit und Tests (`bun test`); Node ist kein Ziel.
- **ADR-006 (2026-09-25)**: TUI-Eigenbau verworfen - [skill-manager](https://github.com/abubakarsiddik31/skill-manager) und [SkillSpector](https://github.com/NVIDIA/SkillSpector) uebernehmen Baum/Multi-Select/Install/Suche/Risk-Scan. Verbleibend: Analyse-CLI (Slice 1), optionaler SkillSpector-Scan, Mirror-Gruppierung (Slice 5) als Backlog. `@opentui/core` bleibt bis zur Backlog-Entscheidung installiert.
- **Original-Bibliothek nur lesen**: `~/.agents/skills/` wird von diesem Tool nie verändert; Schreibzugriffe nur auf `src/data/` (gitignored) und später den Mirror `~/.agents/skills-org/` (ADR-005).
- **Test-Seams** (ADR-004): Lib-Funktionen pure mit injiziertem Root → tmp-Fixtures. Der TUI-Renderer-Seam ist nach ADR-006 obsolet (keine TUI mehr); kein fs.watch-Timing-Test, kein echtes routed in Tests.
- **Conventional Commits + CHANGELOG**: `feat`/`fix` ohne `[Unreleased]`-Eintrag scheitern am CI-Drift-Check (`scripts/check-changelog.ts`).
- **Skripte**: `check-commits.ts`/`check-changelog.ts` sind bewusst dependency-frei (bun stdlib), damit `bunx` sie ohne Install läuft.
- **State/Migration**: `state.json`-Format nur erweitern, nie umbauen – alte States müssen weiter lesbar bleiben (Move-Erkennung hängt am Hash).
- Doku-Einstieg: `docs/INDEX.md`; Issue-Map mit Dependencies in `docs/PROCESS.md`.
- **Nur AGENTS.md** (keine CLAUDE.md mehr in diesem Repo - Konvention: AGENTS.md ueberall).
