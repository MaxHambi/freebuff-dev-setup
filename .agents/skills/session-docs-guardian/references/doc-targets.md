# Doc Targets Referenz

Vollstaendige Liste der Doku-Artefakte, die der Guardian prueft, mit
Prioritaet und Trigger-Bedingung.

## Prioritaet 1 - Entscheider (ADRs)

| Artefakt | Pfad | Trigger |
|----------|------|---------|
| ADR | `docs/decisions/NNNN-slug.md` | Diese Session traf eine Entscheidung, die teuer rueckgaengig ist (Runtime, Datenmodell, Architektur, Prozess) |

Format: Status (Accepted/Superseded/Deprecated) + Date + Context + Decision +
Alternatives Considered + Consequences. Nummer = highest existing + 1.
Bestehende ADRs niemals umschreiben - neue ADR supersedet.

## Prioritaet 2 - Changelog (CI-Gate)

| Artefakt | Pfad | Trigger |
|----------|------|---------|
| CHANGELOG | `CHANGELOG.md` | feat/fix-Commits sind seit dem letzten Changelog-Update dazugekommen |

Keep a Changelog: `[Unreleased]` mit Added / Fixed / Security / Changed /
Removed. Der CI-Drift-Check (`skills-manager/scripts/check-changelog.ts`)
scheitert sonst.

## Prioritaet 2b - AGENTS.md (Agent-Konventionen)

| Abschnitt | Trigger |
|-----------|---------|
| Struktur-Tabelle | Neue Top-Level-Direktive oder Statuswechsel (Slice fertig/offen) |
| File-Scoped Commands | Neues npm/bun/pwsh-Script, neues Check-Skript |
| CI | Neuer Workflow oder neue Check-Stufe |
| Key Conventions | Neue harte Regel (insb. wenn sie aus einem ADR stammt - ADR verlinken) |
| MCP-Server / Session-Ende | Aenderung an `.cline/mcp_settings.json`, neue Hooks/Skills mit Hook-Bezug |

**Namenskonvention:** Ordnerebene-Agent-Dateien heissen immer `AGENTS.md`
(never CLAUDE.md). Das Root-`CLAUDE.md` ist nur ein lokaler Symlink auf
`AGENTS.md` (gitignored). Bei Aenderungen an Konventionen: erst AGENTS.md,
dann ggf. README, dann ADR.

## Prioritaet 3 - README (Einstiegspunkt)

| Abschnitt | Trigger |
|-----------|---------|
| Komponenten-Tabelle (Kopf) | Neue Top-Level-Direktive oder geaenderter Zweck |
| Komponenten-Abschnitt | Neues Verhalten, neue Flags, neue Calls in einem Bereich |
| Skills-Tabelle | Skill erstellt, installiert oder aktualisiert (auch nur in der Bibliothek) |
| MCP-Server-/Workflows-Abschnitt | Aenderungen an `.cline/mcp_settings.json` oder Workflows |
| Deploy-/Task-Abschnitte | Aenderungen an `scripts/` oder `task/` |

## Prioritaet 4 - Komponenten-Doku

| Artefakt | Pfad | Trigger |
|----------|------|---------|
| PRD | `skills-manager/docs/PRD.md` | Scope-Aenderung am Skills-Manager |
| PROCESS | `skills-manager/docs/PROCESS.md` | Aenderung am Issue-Map oder Workflow pro Issue |
| ARCHITECTURE | `skills-manager/docs/ARCHITECTURE.md` | Neues Modul, neuer Datenfluss |
| API | `skills-manager/docs/API.md` | Neue/geaenderte oeffentliche Funktion |
| USER_GUIDE | `skills-manager/docs/USER_GUIDE.md` | Neue CLI-Flags, neue Badges, neues Verhalten |
| INDEX | `skills-manager/docs/INDEX.md` und `docs/index.md` | Neue Doku-Artefakte ueberhaupt |

## Prioritaet 5 - Session-Summary

| Artefakt | Pfad | Trigger |
|----------|------|---------|
| Session-Summary | `docs/sessions.md` | Immer am Session-Ende mit Fazit-Arbeit |

Format pro Session:

```markdown
## YYYY-MM-DD - <Kurzthema>

**Geliefert:** PRs/issues (Nummern), Kern-Artefakte
**Entscheidungen:** ADR-Nummern oder Kurzbeschreibung
**Offen:** Issue-Nummern bzw. ein Satz zum Rest
```

## Stale-Detection-Logik (Hook)

Der Hook `hooks/session-end.ps1` findet den letzten Commit, der nur
Doku-Pfade anfasste, und meldet alle Code-Aenderungen seitdem plus
uncommitted Aenderungen. Klassifizierung nach der Tabelle oben.
Exit immer 0 (Hook blockiert nie), mit `-Check` Exit 1 bei Befund.
