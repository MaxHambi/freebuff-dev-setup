# Routing-Referenz (Phase-Baum, Kategorie-Routing, Interview)

Provenienz: Phase-Baum und Operating Behaviors aus `using-agent-skills`,
Kategorie-Routing und Interview-Funnel aus `skill-router`, komprimiert und
vereinheitlicht. routed-MCP-Details stehen in `routed-mcp.md`.

## Vollständiger Phase-Baum

```
Task kommt rein
    ├── Ziel noch unklar? ─────────────────→ interview (unten) / interview-me / brainstorming
    ├── Grobe Idee, Varianten noetig? ─────→ idea-refine
    ├── Neues Projekt/Feature/Change? ─────→ spec-driven-development
    ├── Keine Quality-Bar geschrieben? ────→ constraint-driven-development
    ├── Spec da, Tasks noetig? ────────────→ planning-and-task-breakdown
    ├── Code implementieren? ──────────────→ incremental-implementation
    │   ├── UI? ───────────────────────────→ frontend-ui-engineering
    │   ├── API? ──────────────────────────→ api-and-interface-design
    │   ├── Besserer Kontext noetig? ──────→ context-engineering
    │   ├── Doku-verifizierter Code? ──────→ source-driven-development
    │   └── Hohes Risiko/unklarer Code? ───→ doubt-driven-development
    ├── Tests schreiben/laufen? ───────────→ test-driven-development
    │   └── Browser-basiert? ──────────────→ browser-testing-with-devtools
    ├── Etwas kaputt? ─────────────────────→ systematic-debugging
    ├── Code-Review? ──────────────────────→ code-review-and-quality
    │   ├── Zu komplex? ───────────────────→ code-simplification
    │   ├── Security? ─────────────────────→ security-and-hardening
    │   └── Performance? ──────────────────→ performance-optimization
    ├── Commit/Branch? ────────────────────→ git-workflow-and-versioning
    ├── CI/CD? ────────────────────────────→ ci-cd-and-automation
    ├── Deprecation/Migration? ────────────→ deprecation-and-migration
    ├── Docs/ADRs? ────────────────────────→ documentation-and-adrs
    ├── Logs/Metrics/Alerts? ──────────────→ observability-and-instrumentation
    └── Deploy/Launch? ────────────────────→ shipping-and-launch
```

Nicht installiert oder keine Sektion passt? -> routed-Discovery
(`route_skill` -> `get_skill`, siehe `routed-mcp.md`).

## Kategorie-Routing (Kurzform)

| Kategorie | Primär | Ergänzend |
|---|---|---|
| Full App/Product | app-builder | brainstorming -> plan-writing |
| Frontend-Feature/UI | frontend-design / senior-fullstack | react-patterns, ui-ux-pro-max |
| Backend/API | backend-dev-guidelines | api-patterns, database-design |
| Debugging | systematic-debugging | test-fixing, clean-code |
| Tests/TDD | tdd | playwright-skill, testing-patterns |
| 3rd-Party-Integration | domänenspezifisch (stripe-integration, clerk-auth, ...) | file-uploads, analytics-tracking |
| AI/LLM/Agents | ai-agents-architect | rag-engineer, prompt-engineer, langgraph |
| Security/Pentest | ethical-hacking-methodology + pentest-checklist | burp-suite-testing, top-web-vulnerabilities |
| DevOps/Infra | docker-expert / cloud-spezifisch | git-pushing, using-git-worktrees |
| Marketing/SEO | seo-fundamentals + seo-audit | copywriting, launch-strategy |
| Planung/Architektur | plan-writing | software-architecture, concise-planning |
| Autonom/parallel | subagent-driven-development | dispatching-parallel-agents |
| Dokumente | docx-official / pdf-official / xlsx-official / pptx-official | - |

Regeln: max. 1 primär + 2 sekundär, upstreamesten Skill zuerst wählen,
bei vager Idee brainstorming statt direkt builder.

## Interview-Funnel (wenn das Ziel vage ist)

Eine Frage nach der anderen, überspringen was die vorige Antwort erledigt.
Vor dem Interview keine Skills empfehlen.

1. **Bereich?** Bauen/Coden - Fixen/Debuggen - Security - AI/LLM - Marketing -
   DevOps/Git - Design/UI - Planung/Doku - Sonstiges (beschreiben lassen).
2. **Spezifität?** Klare Spec - grobe Idee - kompletter Neustart ohne Richtung.
3. **Stack/Domain?** Nur wenn relevant; "nicht sicher" ist eine gültige Antwort.
4. **Arbeitsmodus?** Vollautonom - kollaborativ mit Review - noch offen.

### Empfehlungsformat (danach)

```
Primary: @skill-name
Warum: 1-2 Saetze zum Fit.
Aufruf: @skill-name <Ziel des Nutzers>

Auch moeglich:
- @skill-2 - wann man ihn dazuschaltet (1 Satz)
- @skill-3 - wann man ihn dazuschaltet (1 Satz)
```

Danach anbieten, einen fertigen Copy-Paste-Prompt zu schreiben. Bei totaler
Orientierungslosigkeit: default auf brainstorming (offenes Ziel) bzw.
app-builder (alles mit Bauen zu tun).

## Lifecycle-Sequenz (vollständiges Feature, optional)

interview-me -> idea-refine -> spec-driven-development ->
planning-and-task-breakdown -> incremental-implementation (parallel:
observability-and-instrumentation) -> test-driven-development ->
code-review-and-quality -> code-simplification -> git-workflow-and-versioning
-> documentation-and-adrs -> shipping-and-launch. Ein Bugfix braucht meist nur
systematic-debugging -> test-driven-development -> code-review-and-quality.
