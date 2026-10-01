# AGENTS.md

Instructions for AI coding agents working in this project. This is the cross-tool
entry point: Codex, Cursor, GitHub Copilot, Gemini CLI, Aider, Zed, Windsurf, and
others read `AGENTS.md`. Claude Code reads `CLAUDE.md`, which imports this file, so
there is a single source of truth.

## What this is

`freebuff-dev-setup` - Windows Scheduled Tasks & Watchdogs as code, plus der
Skills-Manager (Analyse-CLI fuer `~/.agents/skills`, ueber 1.800 Skills) und
eigene Agent Skills (`skills/using-skills`). Landkarten: `README.md`
(Komponenten), `docs/index.md` (Doku), `docs/issue-fibel.md` und
`docs/worktree-fibel.md` (Prozess).

**Namenskonvention:** Ordnerebene-Agent-Dateien heissen in diesem Repo immer
`AGENTS.md` - nie `CLAUDE.md`. Das Root-`CLAUDE.md` ist nur ein lokaler,
gitignoreter Symlink auf `AGENTS.md`.

This project is built with the **AI Blueprint**, a workflow layer, not an
app skeleton. To start a new project, scaffold the app first in an empty folder
(create-next-app, Vite, etc.), then overlay these files on top. Never run a
framework scaffolder inside a directory that already holds the blueprint files
(`AGENTS.md`, `CLAUDE.md`, `.agents/`, `.claude/`, `blueprint/`); it fails
because the directory isn't empty.

The workflow is defined by the local skills and context files below.

## Read these for full context

- `blueprint/context/project-overview.md` - the project's source of truth
- `blueprint/context/coding-standards.md` - conventions to follow
- `blueprint/context/ai-interaction.md` - how to work with the user on this project
- `blueprint/context/current-feature.md` - the one feature, fix, or rollback being built right now
- `docs/issue-fibel.md` - Issue-Layouts, Label-Statusuebergaenge und Handoff-Regeln (Schwester der Worktree-Fibel)
- `docs/mempalace-regeln.md` - verbindliche MemPalace-Regeln (Recall-Protokoll, Drawer-/KG-Konvention, Ingest, Diagnose)
- `docs/mempalace-uebersicht.md` - Inhaltsverzeichnis des MemPalace-Palasts (was liegt wo; Einstieg auch via `mempalace search "Palast-Index"`, siehe ADR-011)

## Workflow

Build one feature, fix, or rollback at a time, behind review gates. Each step's instructions
are plain markdown skills any capable agent can read and follow. The workflow is
exposed through tool-specific adapters:

- Codex: `.agents/skills/<skill>/SKILL.md`
- Claude Code: `.claude/skills/<skill>/SKILL.md`
- GitHub Copilot: `AGENTS.md` plus `.agents/skills/<skill>/SKILL.md`
- Freebuff: `AGENTS.md` plus `.agents/skills/<skill>/SKILL.md`

Unused adapters can be removed. Codex, GitHub Copilot, and Freebuff share `.agents/`.
Codex-only, Copilot-only, or Freebuff-only projects can delete `CLAUDE.md` and `.claude/`.
Claude Code-only projects can delete `.agents/`, but should keep `AGENTS.md`
because `CLAUDE.md` imports it.

When changing shared workflow behavior, update the matching skill in both
adapter folders so Codex, Claude Code, and GitHub Copilot stay aligned.

Core skills:

- `onboard` - tune commands, standards, visibility, ignore rules, and tool adapters after overlaying the Blueprint onto a freshly scaffolded or early project
- `discovery` - optional deep, multi-turn planning conversation that drafts the two user-owned plans only after review and approval; direct plan writing remains fully supported
- `doctor` - read-only Blueprint health check for setup, adapters, plans, overview freshness, and workflow drift
- `adopt` - bootstrap the Blueprint into an existing brownfield app with shipped features
- `overview` - distill the two planning docs into `blueprint/context/project-overview.md`
- `brief` - read-only briefing on an upcoming build-plan feature (scope, dependencies, size) before you spec it
- `feature` - turn a build-plan item into a spec, or propose a reviewed plan addition for a genuinely new feature
- `debug` - reproduce and isolate a failure without editing code, then hand the evidence to `fix` or `implement`
- `fix` - document an ad-hoc bug or change into `blueprint/context/current-feature.md`
- `tests` - add or normalize unit testing and turn on the test gate
- `ci` - explicitly set up one project-specific Verify command and matching automatic GitHub checks
- `implement` - build the current spec one small, reviewed step at a time
- `check` - prove the current spec against the running app
- `try` - read-only manual review guide: where to go, what to click, what to expect
- `audit` - branch-aware or full-project review across all concerns or a focused quality, security, performance, or tests lens; records findings with durable IDs and statuses in `blueprint/context/findings.md`, where open or fixed P0/P1 findings block `complete`
- `rollback` - plan a safe reversal of a completed feature from its archive and exact git commit, with later-dependency review before code changes
- `complete` - run the final safety pass, log features, fixes, or rollbacks under `blueprint/history/`, then merge with approval
- `release` - optional Render or Vercel deployment readiness, local config, env review, and smoke-test planning
- `prototype` - optional, pre-build static mockups to lock the look
- `status` - read-only progress summary, workflow drift warning, and suggested next action

In Codex, invoke these as skills (`$onboard`, `$discovery`, `$overview`, `$feature`,
`$implement`, and so on) or ask naturally, such as "run the overview." In Claude
Code, use the slash commands (`/onboard`, `/discovery`, `/overview`, `/feature`,
and so on). In Freebuff, ask naturally, such as "run the overview" or
"implement the current feature" - Freebuff reads the matching `.agents/skills/`
SKILL.md files and follows them. In tools without native skills, follow the
matching `SKILL.md` manually. The conventions in `blueprint/context/` apply
however a step is invoked. `/discovery` is never required: users may write detailed plans directly
or develop them through any conversation before running `/overview`.

Optional explicit-only skill: `autopilot` can run one bounded spec/build/check
and targeted-audit pass when directly invoked. It may create checkpoint commits
on the feature or fix branch after passing steps, repair confirmed P0/P1 findings
within scope, and rerun affected checks. It stops before `/complete`, merge, push,
deploy, or destructive actions.

Deployment is also explicit. `/release` can prepare local Render or Vercel config
and run readiness checks, but it must stop before deploy, remote service changes,
push, or publish unless the user gives a separate yes in the current chat.

## Automatic verification

Automatic GitHub checks are a separate explicit setup. `/onboard` and `/adopt`
only report existing checks and point to `/ci` or `$ci` when none exist. Running
`/ci` inspects the real project and defines one `Verify` command from checks that
already exist. Use this order when available: typecheck, tests, then build. Never
invent a test runner or another check just to fill the command.

For JavaScript and TypeScript projects, prefer a package script such as `verify`
and use the detected package manager. For other stacks, use the native task
runner or exact combined command. Record the exact command under Commands below.

The optional `.github/workflows/verify.yml` must run that same command for pull
requests and pushes to the default branch. Preserve existing workflows, use the
project's real runtime and install command, and grant only `contents: read` by
default. This setup does not add local git hooks, coverage, browser tests,
security scans, or version matrices. Those remain later project choices.

GitHub branch protection or a ruleset can require the check after the repository
is pushed, but that is a separate remote setting. Missing automatic GitHub
checks do not make the Blueprint unusable.

## Commands

Bun/TypeScript-Teil (skills-manager) und PowerShell-Operations-Teil:

- Tests: `bun test` (41 Tests gegen tmp-Fixtures) - Test-Gate ist aktiv
- Lint: `npx biome lint skills-manager --max-diagnostics=none` und `npx biome lint memory-ingest --max-diagnostics=none`
- Typecheck: `bunx tsc --noEmit`
- PowerShell-Syntaxcheck: `npm run syntaxcheck` (alle Repo-PS-Skripte)
- Konventions-Wächter: `pwsh -File scripts/check-conventions.ps1` (Claude-Bann: keine getrackten CLAUDE.md/.claude-Artefakte + Mirror-Sync-Header-Pflicht)
- Analyse-CLI: `bun run skills-manager/src/analyze.ts [--root <pfad>] [--quiet]`
- Doku-Gates (CI-identisch): `bun run skills-manager/scripts/check-commits.ts --base origin/master` und `check-changelog.ts --base origin/master`
- Watchdog-Integrationstests (nur Windows): `pwsh -File node-watchdog/run-tests.ps1`
- Memory-Ingest (Session -> Palast): `pwsh -File memory-ingest/ingest.ps1` (DryRun: `-DryRun`; Task `MemoryIngest` via `install-task.ps1 -Register`) - Details in README-Abschnitt "Memory-Ingest"
- MemPalace-Diagnose (Consent/Binary/Suche): `pwsh -File memory-ingest/check-mempalace.ps1` (Exit 0/1/2)
- Issue-Mirror-Sync: `pwsh -File scripts/mirror-sync.ps1 [-Update]` (SHA-256-Header je Mirror gegen GitHub-Issue-Body; `-Check` schlägt bei Drift/fehlendem Header fehl)
- Deploy-Pipeline (Reihenfolge): `npm run deploy` → `npm run install-task` → `npm run export-tasks`
- **Verify (kanonisches Gate, alles oben zusammen):** `npm run verify` - der Pre-Push-Hook (`scripts/hooks/pre-push`) ruft genau diesen Befehl

Quality-Gate: `scripts/hooks/pre-push` (Lint + Syntaxcheck + Tests) laeuft
bei jedem Push (`core.hooksPath=scripts/hooks` ist gesetzt). Conventional
Commits und CHANGELOG `[Unreleased]` sind CI-pflichtig (Drift-Checks).

Verifikationsdisziplin: Status-Claims („erledigt/implementiert“) nur mit
Beweis setzen (Befehl+Ausgabe, Commit-SHA oder Testlauf) - nie aus
Erinnerung. Am Session-Ende: Verifikationspass ueber alle Gates und Claims
der Session.

Learnings (nicht aus Code ableitbar):
- Task-Fenster-Flash: Task-Aktionen nie direkt `powershell.exe
  -WindowStyle Hidden` starten (conhost-Fenster entsteht, bevor der
  Schalter verarbeitet wird); immer `wscript.exe //B //Nologo
  run-hidden.vbs <skript.ps1> [args]` - install-task.ps1 erzeugt nur
  noch Wrapper-Aktionen, Migration nur per XML-Round-Trip (ADR-014,
  audit/2026-10-01-fenster-flash).
- Plan-/Schaetzzahlen in Doku immer als „gemessen“ oder „geschätzt“
  markieren (C10): Schätzflächen (z. B. „22/22 PASS“) verlieren gegen
  Messungen („21/21 PASS, 3 Läufe“) — die Messung ist Autorität und der
  Plan wird nachgezogen, nie umgekehrt.
- routed-CLI: `scan` hat keinen Help-Guard (`scan --help` führt einen
  echten, index-kürzenden Scan aus) und pruned global; Registrierung nur
  via MCP `scan_skills` (Issue #15, upstream bshea-1/Routed#2).
- Watchdog-Port-Erkennung MUSS `Get-NetTCPConnection -State Listen` nutzen;
  netstat-String-Matching bricht auf nicht-englischen Windows-UIs
  (`ABHOeREN` statt `LISTENING`) - ADR-001/H2.
- Node-spawned Kinder ueberleben auf Windows den Eltern-Exit nie (Job-
  Objekt), ausser mit `detached: true` - relevant fuer alle Harness,
  die echte Waisen testen wollen (ADR-001/H7).
- Watchdog-Task laeuft bindend mit `-Apply` (plan.md); `install-task.ps1`
  vergibt StartWhenAvailable + ExecutionTimeLimit (Watchdog PT5M) - ohne
  StartWhenAllowed 0x41303, mit laenger haengenden Instanzen sonst
  IgnoreNew-0x800710E0.
- Skills-Fallback-Kette (ADR-012): Repo `.agents/skills/` → User-Level
  `~/.agents/skills/` → `.disabled/` nur mit dokumentiertem Re-Enable;
  Repo-Skill loeschen nur bei existierender User-Level-Kopie.
- Issue-Mirror-Contract: Zeile 2 traegt `mirror-sync`-SHA-Header;
  `scripts/mirror-sync.ps1 -Update` staempelt, `-Check` ist im Verify-Gate.
  Issue-Loeschung: mirror-first, nie umgekehrt.
- `deploy.ps1` ohne `-Force` ueberschreibt Runtime nie (KEEP-Logik) - nach
  Code-Fixes am Watchdog ist ein `-Force`-Deploy + Log-Stichprobe Pflicht.

---

<!-- mempalace-shared-brain:start (canonical source: mempalace repo integrations/shared/coordination-protocol.md — edit there, re-render with `mempalace rules --host maxhambi --harness freebuff --project freebuff-dev-setup`) -->

## MemPalace shared brain

You share a MemPalace hub with other agents. Your agent identity is
host:harness:project — on this machine maxhambi:freebuff:<project>, where
<project> is the current workspace/repo name (lowercase, e.g.
maxhambi:freebuff:freebuff-dev-setup). Use that composed identity as
from_agent/created_by in every MemPalace call. Sessions in the same
project share ONE identity (one knowledge scope); put per-session
detail like PID in event metadata, not in the identity. Never
impersonate another agent. Never mint a second harness suffix to split
windows — parallel lanes use topic, not a forged identity.

Memory (recall + writing):
- Before answering about past work, decisions, people, or projects,
  search the palace (mempalace_search; mempalace_kg_query for
  relational/temporal facts). Quote results verbatim — never paraphrase
  stored content. If the palace has nothing, say so; don't guess.
- File durable outcomes (decisions, conclusions, learned facts) with
  mempalace_add_drawer. New KG facts: mempalace_kg_add. When a
  single-valued fact changes: mempalace_kg_supersede. When a fact ended
  without replacement: mempalace_kg_invalidate. Don't file secrets or
  tokens.

Coordination (logstream):
- Chat sessions are declared-idle until a coordination loop starts.
  Do not arm a background watcher at session start. Focus on the user's
  request first; engage the logstream when collaborating, delegating,
  or when asked to listen.
- Inbox: when entering collaborative mode or before long tasks,
  mempalace_event_list with to_agent=maxhambi:freebuff:<project>,
  since_event_id=<last event id you processed>, preview=true. Omit
  order: a resume from a cursor is chronological, and with no cursor
  the same call returns newest-first. Remember that id — it is your
  cursor. Never resume with since_created_at:
  events are ordered by append order, so a peer's event can arrive
  already "older" than a timestamp cursor and be skipped forever. '*'
  broadcasts match automatically.
- Arm mempalace logstream watch (and re-arm after every wake) when any
  of these happen — not before: (1) the user asked you to listen or
  coordinate, (2) you ack a task with status=claimed, (3) you delegate
  (append a task.request). Command:
  `mempalace logstream watch --agent maxhambi:freebuff:<project>
  --type task.request --type task.reply --type patch.ready --json`
  Use --agent, not --to-agent: it also excludes your own events. The
  CLI defaults a sanitized --state-file from --agent. Treat exit 0 as
  mail and exit 2 as idle. Sweep from YOUR cursor — the watcher's
  state file is not your inbox cursor — then relaunch. In-turn,
  waiting on one known correlation, mempalace_event_wait complements
  the watcher, never replaces it. If this machine is a remote MCP
  client and does not own the palace or a synced replica, do not run
  local logstream watch; loop on mempalace_event_wait and carry
  since_event_id.
- When you arm a watcher, announce once (type=status, room=status,
  to_agent=*) naming your filter and cursor so others know you are
  listening. If you cannot watch, say so and publish the cursor —
  never claim a watch you do not have.
- Acks: mempalace_event_ack (CLI: `mempalace logstream ack`) — it
  fills type=event.ack and the ack_of link; don't hand-roll event.ack
  appends. Acks inherit the target event's topic.
- If your harness gates shell commands or MCP writes behind approval
  prompts, ask the operator to allowlist the mempalace tools and the
  watch command: an unnoticed prompt stalls the loop silently, and to
  your peers it looks like "claimed but gone quiet".
- Topics: write topic=<lane> on named workstreams (e.g. auth-v2). Do
  not filter the default inbox or watcher on topic unless you
  announced that filter. Stream = project/scope, room = lifecycle
  (delegation/reviews/status), topic = optional lane.
- To delegate: mempalace_event_append (type=task.request, stream=
  project/<name>, room=delegation, topic=<lane if any>,
  correlation_id=task_..., status=open, body = goal + branch + base
  commit + definition of done), then mempalace_event_wait on that
  correlation_id.
- When you accept a task: first check the correlation for an existing
  status=claimed from your OWN identity — a sibling session on the
  same project may already own it; if so, don't double-work (on a
  simultaneous claim, lowest-HLC wins). Then ack with status=claimed.
  Deliver code as a patch via mempalace_patch_submit (never just push
  a branch and go silent). If blocked, reply with status=blocked and
  verbatim notes.
- When you receive a patch: mempalace_artifact_get, verify sha256,
  apply only with explicit user-visible intent, run the stated tests,
  then mempalace_event_ack with status=applied or failed.
- Events are append-only and verbatim. Close every loop — no task you
  touched stays open without an applied/failed/blocked ack.

<!-- mempalace-shared-brain:end -->
