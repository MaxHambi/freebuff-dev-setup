---
name: using-skills
description: Unified meta-skill gate and router - invoke at session start and before any response or action. Enforces the 1% skill-invocation gate, routes to the right skill via the phase tree, interviews the user when the goal is vague, discovers skills via the routed MCP server (route_skill, get_skill, list_skills, scan_skills), and ships hooks (route-gate.ps1 for gate enforcement, skills-sync.ps1 for index registration). Triggers (de): "Welcher Skill passt", "Skills aufraeumen und registrieren", "Wo starten", "Skill-Gate".
risk: safe
source: self
---

# Using Skills (Gate + Router)

## Purpose

One meta-skill that unifies three sources into one workflow:

- `using-superpowers` -> the GATE (when to invoke: hard 1% rule).
- `using-agent-skills` -> the ROUTER (which skill, how to work).
- `skill-router` -> the INTERVIEW (help when the user is lost).

Plus: skill discovery through the local `routed` MCP server and an automation hook for mechanical gate enforcement.

## Step 1 - The Gate (before ANY response or action)

- If there is even a 1% chance a skill might apply, invoke it BEFORE responding - including before clarifying questions, exploring files, or gathering context.
- Announce: "Using [skill] to [purpose]".
- Invocation is not obedience: if the skill's premise does not hold (wrong domain, missing inputs, contradicts user instructions), announce it and drop it.
- Subagents dispatched for one specific task may skip this gate; the coordinating agent must not.

## Step 2 - Route: which skill?

Quick tree (full tree + category routing: `references/routing-reference.md`):

```
Goal unclear / user is lost?  -> interview (Step 3) or interview-me / brainstorming
New project/feature/change?   -> spec-driven-development
Implementing code?            -> incremental-implementation (+ domain skill)
Writing/running tests?        -> test-driven-development
Something broke?              -> systematic-debugging
Reviewing code?               -> code-review-and-quality
Committing/branching?         -> git-workflow-and-versioning
Docs/ADRs?                    -> documentation-and-adrs
Skill design/authoring?       -> skill-designer (Skill erstellen/verbessern/strukturieren)
Implementing (TDD-Standard)?  -> tdd-workflows (red/green/refactor) + tdd-orchestrator
Commit/PR-Workflow?           -> git-pr-workflows-git-workflow (+ -pr-enhance)
Issue fixen/triagen?          -> team-collaboration-issue
Boards/Sprints verwalten?     -> github-project-management
Deploying/launching?          -> shipping-and-launch
None fit or not installed?    -> routed discovery (Step 4)
```

Process skills come before implementation skills. User instructions and project files (AGENTS.md, CLAUDE.md, GEMINI.md) take precedence over skills; skills override default behavior.

## Step 3 - Interview when the goal is vague

If the user cannot name what they want, run the interview funnel from `references/routing-reference.md`: one question at a time (area -> specificity -> stack -> autonomy), then recommend exactly 1 primary + max 2 secondary skills with copy-pasteable invocation syntax. Do not dump the whole skill list.

## Step 4 - Discovery via routed MCP

If no listed skill fits, or to verify a better match exists, query the local routed index BEFORE working without a skill:

- **`route_skill`** with the task prompt (topK 3) -> take the best match by score/confidence.
- **`get_skill`** with the matched skill's id -> read and follow its SKILL.md.
- **`list_skills`** (filter substring) to browse what is installed.
- **`scan_skills`** after installing or editing skills, so the index is fresh.
- **`record_feedback`** after the user corrects a route - trains future routing.
- **CLI fallback** (MCP unavailable): `pwsh -File hooks/route-gate.ps1 -Prompt "<task>"` or `routed route --json "<task>"`.

Tool signatures, failure signatures, and index locations: `references/routed-mcp.md`.

## Step 5 - Work with the selected skill

Apply the operating behaviors while following the skill: surface assumptions before non-trivial work, stop and name confusion instead of guessing, push back with concrete downsides, prefer the boring simple solution, touch only what the task requires, verify with evidence (tests, build output, runtime data).

## Red Flags (rationalizing means STOP)

| Thought | Reality |
|---------|---------|
| "Just a simple question" | Questions are tasks. Check for skills. |
| "I need more context first" | Skill check comes BEFORE clarifying questions. |
| "Let me explore the codebase first" | Skills tell you HOW to explore. |
| "The skill is overkill" | Simple things become complex. Use it. |
| "I remember this skill" | Skills evolve. Read the current version. |
| "routed has no match anyway" | One route_skill call costs seconds. Check. |

## Internationalization (i18n)

Trigger-language rules for this skill:

- The skill body stays in English (ecosystem convention; consuming LLMs are multilingual). Do NOT translate skill instructions per user locale.
- **Trigger surface is bilingual**: the description carries English and German trigger nouns ("skill invocation gate", "which skill applies", "Welcher Skill passt", "Skills aufräumen") so routed's BM25 index and keyword matching catch German prompts too. Keep it bilingual when editing.
- Respond in the user's language (German prompts get German answers); skill invocations and tool names stay verbatim.
- The interview funnel and recommendations are delivered in the user's language; skill names stay `@skill-name`.
- routed matching detail: BM25 is lexical - German-only phrasings route poorly against English-only descriptions. Fix at the source: add the German terms to the target skill's description instead of duplicating the skill.

## Automation hooks

**Gate enforcement** - `hooks/route-gate.ps1 -Prompt "<task>"`: routes via the routed CLI and exits `1` when a skill matched. Wire it as a session-start or file-change hook to enforce the gate mechanically on platforms where MCP is not yet available. Exit codes: `0` = no skill needed, `1` = invoke the listed skill(s), `2` = routed unreachable.

**Index sync** - `hooks/skills-sync.ps1`: detects changes in the skills folders (`.gemini\config\plugins`, `.agents\skills`, `.claude\skills`) by comparing a SKILL.md snapshot against the last run state in `%APPDATA%\routed\skills-sync.state.json` and registers updates with `routed scan`. Run it after installing, editing, moving, or cleaning up skills - it is the registration step for library reorganization. Switches: `-Force` (scan regardless of diff), `-HashContent` (SHA-256 content hash instead of timestamp+size, catches same-size edits). Exit codes: `0` = index up to date, `1` = changes detected and registered, `2` = error. MCP alternative: `scan_skills` tool.

## When to Use

- At session start, before the first response of every conversation.
- Whenever a new task arrives mid-conversation.
- When unsure which skill applies or the user says "I don't know where to start".

## Limitations

- routed only sees indexed skills - run `scan_skills` after installing new ones, otherwise matches are stale.
- A high routing score does not replace reading the SKILL.md before following it.
- This skill selects and gates other skills; it does not replace them.
- The hook uses the CLI (works outside MCP); inside MCP sessions prefer the native tools.
