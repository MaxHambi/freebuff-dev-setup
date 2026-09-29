# #61: .agents/skills ausduennen - Repo-Skills auf Blueprint-Workflow + git/gh/github-Set beschraenken (Slice 2 Struktur-Plan)

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#61](https://github.com/MaxHambi/freebuff-dev-setup/issues/61).
> Label: `ready-for-agent`. Status: in Arbeit (Slice 2 des Struktur-Plans
> `docs/plan-2026-09-29-struktur-ordnung.md`).

## Kontext

36 ungetrackte Skill-Ordner liegen neu in `.agents/skills/`. Fast alle existieren identisch auf User-Level (`~/.agents/skills`) und sind dort gemeint. Operator-Entscheid (Struktur-Plan, Slice 2): **Ausduennen**.

## Ziel-Layout

Repo `.agents/skills/` = Blueprint-Workflow-Skills (repo-owned, bereits getrackt) + git/gh/github-Set + Session-Skills ohne User-Level-Kopie. Persoenliche Bibliothek bleibt auf User-Level.

**Keep (14):** agents-md, analyze-project, brainstorming, session-docs-guardian, blueprint + git-advanced-workflows, git-pr-workflows-git-workflow, git-pr-workflows-pr-enhance, github, github-actions-advanced, github-actions-templates, github-presence, github-workflow-automation, gitops-workflow

**Delete (20, Duplikate von User-Level):** agenttrace-session-audit, api-documentation-generator, c4-architecture-c4-architecture, c4-code, c4-component, c4-container, c4-context, code-documentation-code-explain, code-documentation-doc-generate, code-refactoring-refactor-clean, context-driven-development, docs-architect, fp-pragmatic, fp-ts-pragmatic, gm, gm-continue, observability-and-instrumentation, prd, source-driven-development, wfgy-method

**Behalten mangels User-Level-Kopie (Safety-Check):** idea-refine, security-bluebook-builder

## Fallback-Kette (ADR-012)

Repo `.agents/skills/` → User-Level `~/.agents/skills/` → nur bei echter Notwendigkeit `~/.agents/skills/.disabled/` (Re-Enable wird dokumentiert, nie still).

## Verwandt

- #20 (gm-Evaluierung): Repo-seitige Entfernung von gm/gm-continue verweist auf die User-Level-Bibliothek; finale Evaluierungs-Entscheidung bleibt in #20.
- Gate: `npm run verify` gruen; danach zeigt `git status` nur die Keep-Skills als neu/committet.
