---
name: session-docs-guardian
description: "End-of-session documentation audit and close-out: at session end or on request (wrap up, finalize docs, end of session, mach die Doku fertig, sitzung beenden, Session abschliessen, Doku-Audit), inventory this session's commits/PRs/issues, audit README, AGENTS.md, CHANGELOG, ADRs, PRD/PROCESS and skill docs for staleness, update them, register newly created or installed skills, append the session summary to docs/sessions.md, and commit/push docs-only. Ships hooks/session-end.ps1 for SessionEnd/Stop hook registration. Not for single-doc edits, ADR authoring, doc generation, or skill creation outside a session close-out."
risk: safe
category: documentation
source: self
---

# Session Docs Guardian

End-of-session documentation: audit what this session changed, update the docs it
made stale, and leave a session summary. Runs at session end or on request.

## Core loop

1. **Inventory the session.** Collect from git and the tracker:
   - Commits/merges of this session (`git log --since=<session start>`), merged PRs, created issues
   - New/changed top-level directories and skills
   - Decisions made (anything that would deserve an ADR)
2. **Audit doc staleness.** For each artifact below, decide: still correct? Needs patch? Missing?
   - `AGENTS.md` (root and per-folder, e.g. `skills-manager/AGENTS.md`) — structure table, file-scoped
     commands, CI entries, key conventions, MCP/session-guardian notes. **This repo convention: every
     folder-level agent file is named AGENTS.md — never create CLAUDE.md.** The root `CLAUDE.md` is a
     local-only symlink to AGENTS.md (gitignored).
   - `CHANGELOG.md` — `[Unreleased]` entries (Added/Fixed/Security) for user-relevant changes
   - `docs/decisions/` — ADRs for significant decisions (highest sequential number + 1)
   - `docs/index.md` — doc map (if it exists)
   - AGENTS.md staleness signals: new top-level dir not in the structure table, new commands in
     package.json scripts, new CI workflows, new ADRs not referenced, new conventions in effect
   - Component docs (`<component>/docs/`) — PRD/PROCESS/ARCHITECTURE/API/USER_GUIDE if the component changed
3. **Update in priority order** (highest value first, stop when the user is satisfied):
   1. ADRs for decisions that would be expensive to re-litigate
   2. CHANGELOG `[Unreleased]` (drift-check script will fail CI otherwise)
   3. README component table + affected sections (including new/installed skills, MCP config, workflows)
   4. Component docs touched by this session
4. **Register new skills.** Any skill created or installed this session gets a row in the
   README skills table and, if it is repo-owned, a deploy note (`%USERPROFILE%\.agents\skills\<name>\`).
5. **Session summary.** Append a dated section to `docs/sessions.md` (create if missing):
   what was built, PRs/issues, decisions, open threads. Keep it short — a reader should
   reconstruct the session in 60 seconds.
6. **Commit and push** `docs:` commit(s) with conventional commits, then report what was updated
   and what was intentionally left stale.

## Doc tooling

Use the installed doc skills where they fit:

- `/documentation-generation-doc-generate` or `/code-documentation-doc-generate` — generate/refresh
  API docs, architecture docs, user guides from code
- `/interview-style-doc-building` — when the user wants a strategic doc authored in their words
  (one question at a time, patch, never overwrite)
- `/brain-to-docs` — when vision/decisions should move from conversation into README + ADRs
  (check `docs/adr/` or `docs/decisions/` first; update docs after every answer)
- `/changelog-automation` — Keep a Changelog format for the CHANGELOG
- `/documentation-and-adrs` — ADR template and lifecycle (Status: Accepted/Superseded/Deprecated)

## Rules

- **Docs-only staging.** `git add` is limited to doc paths (README, AGENTS.md, CHANGELOG.md, `docs/`, `*/docs/`) - code files are never staged by this skill, even when they are stale.
- **Never invent content.** Docs state what happened in this session; questions to the user beat guesses.
- **Patch, don't rewrite.** Existing sections get updated in place; the user's wording stays.
- **ADRs are immutable once accepted.** A changed decision becomes a new ADR superseding the old one.
- **Respect project conventions.** Read `AGENTS.md` first (language, commit format, attribution footer).
- **Secrets stay out.** No tokens, internal URLs, or machine paths beyond what the repo already publishes.

## When to Use

- Session is ending and code/PRs/issues changed (default trigger)
- User asks to "finalize docs", "aktualisiere die Doku", "wrap up"
- After merging PRs that touched component docs or introduced new components

## When NOT to Use

- Mid-session doc edits that belong to the feature work itself
- Throwaway prototypes without durable artifacts

## Limitations

- Reads git history and the GitHub tracker (`gh`); if unavailable, falls back to session context only
- Does not run doc-site builds; verifies Markdown only via lint if configured
- Conflicting doc state (merge residue) must be resolved before this skill patches anything
