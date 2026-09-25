# Coding Standards

> Per `/onboard` auf den realen Stack gesetzt (2026-09-25). Stable sections
> from the Blueprint are kept; Next.js/React/Prisma defaults removed.

## Stack (detected)

- **Bun 1.3.6** as runtime and test runner for the TypeScript part
  (`skills-manager/`); Node.js is not a target.
- **TypeScript strict** (`bunx tsc --noEmit` must stay green).
- **PowerShell 5.1** for repo operations scripts (`scripts/`, `node-watchdog/`,
  `skills/*/hooks/`); PS 7 (`pwsh`) is available and used by callers.
- No web UI, no database, no styling - browser sections do not apply.

## TypeScript / Bun

- Strict mode; no `any` - use proper typing or `unknown`
- Bun-style imports with explicit `.ts` extension (`./scan.ts`)
- Injectables pattern: fs-touching functions take root/path parameters so
  tests run against tmp fixtures (ADR-004)
- Errors: throw with clear German user-facing messages; never silent catch -
  degrade explicitly (see `scanSkillsRoot` vs `listDirEntries`)

## PowerShell

- `#Requires -Version 5.1` + `Set-StrictMode -Version Latest` in every script
- Tabs for indentation; UTF-8 without BOM for written files
- Destructive actions behind DryRun-Default + explicit `-Apply` (see
  `node-watchdog.ps1`); `ShouldProcess` where applicable
- Every script must pass `npm run syntaxcheck` (parser gate)

## File Organization

- `skills-manager/src/*.ts` - Lib modules (scan, classify, delta, report,
  analyze); `skills-manager/test/*.test.ts` - bun:test files (mirrors src)
- `scripts/` - deploy/task helpers + shared hooks (`pre-push`)
- `node-watchdog/` - watchdog + its integration tests
- `skills/<name>/` - repo-owned agent skills (deployed to `~/.agents/skills/`)
- Docs: `docs/` (map, ADRs, Fibeln, sessions), `skills-manager/docs/`
  (PRD/PROCESS/ARCHITECTURE/API/USER_GUIDE/INDEX, issue mirrors)

## Naming

- Functions/variables: camelCase; types/interfaces: PascalCase (no prefix)
- Constants: SCREAMING_SNAKE_CASE; files: match export or kebab-case
- Branches: `feature|fix|chore/<topic>`; ADRs: `ADR-00N-slug.md`

## Git & Commits

- **Conventional Commits** `<type>(<scope>)?: <why>` - enforced by CI
  (`check-commits.ts`); Merge-/Revert-Subjects sind ausgenommen
- **Attribution footer is mandatory** in every commit:
  `🤖 Generated with Codebuff` + `Co-Authored-By: Codebuff <noreply@codebuff.com>`
- `Refs #<issue>` in commit bodies; `Closes #<issue>` only in PR bodies
- feat/fix commits require a `CHANGELOG.md` `[Unreleased]` entry (CI
  drift-check `check-changelog.ts` fails otherwise)
- Trunk-based on `master`; short-lived branches, Squash-Merge, Pre-Push-Gate
  (`scripts/hooks/pre-push`: lint + syntaxcheck + tests)

## Testing

The test gate is **on**: `bun test` is declared in Commands and runs in the
Pre-Push-Gate and CI (ubuntu + windows).

- 25+ bun tests against tmp fixtures; lib functions are pure with injected
  roots (ADR-004). The TUI renderer seam is obsolete (ADR-006).
- What to test: parsers, classifiers, delta logic, report building - pure
  logic with assertable edges (empty, missing, malformed)
- What not to test: fs.watch timing, real routed calls, PowerShell internals -
  covered by integration DryRuns (`run-tests.ps1`, watchdog harness with
  documented Known-Fails in ADR-001)
- An empty suite fails; test files live in `skills-manager/test/` and run via
  the `bun test` command from Commands in `AGENTS.md`, never a hardcoded path

## Verification (instead of Browser Verification)

No UI exists; evidence comes from: green gates (`bun test`, `tsc`, Biome,
syntaxcheck), CI on both OS targets, runtime DryRuns (watchdog DryRun,
analyze `--quiet` runs), and `gh run list` for CI truth. Playwright is not
installed and is not added silently.

## Code Quality

- No commented-out code unless specified
- No unused imports or variables
- Keep functions under 50 lines when possible

## Comments

Write code that explains itself; comment only what the code cannot say.
Over-commenting is a common AI tell, so resist it.

- Comment the **why**, not the **what**. Delete any comment that restates the code.
- No banner/header blocks, section dividers, or step-by-step narration of obvious
  code. A file does not need a comment announcing each region.
- A comment earns its place only when it captures something the code can't: a
  non-obvious decision, a gotcha or workaround, why a value is what it is, or a
  link to a spec or issue.
- Prefer self-documenting names and small functions over explanatory comments.
- Keep doc comments minimal: a one-line purpose on an exported type or function is
  plenty; don't write JSDoc that just repeats the signature.
- When in doubt, leave the comment out.

## Writing

- No em dashes (U+2014) in generated content: docs, comments, commit messages,
  READMEs, specs. They read as AI-generated.
- Use a hyphen for `term - description` separators; rephrase prose with commas,
  parentheses, or a colon. Avoid en dashes and the ellipsis character too.
- German is the project language for docs and answers; skill bodies and code
  comments may stay English (see `using-skills` i18n rules).
