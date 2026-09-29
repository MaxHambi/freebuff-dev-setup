# ADR-012: Skills-Layout — Repo-Skills beschraenkt, User-Level-Bibliothek, Fallback-Kette

## Status

Accepted

## Datum

2026-09-29

## Kontext

Am 2026-09-29 tauchten 36 ungetrackte Skill-Ordner neu in `.agents/skills/`
auf (Sync des Operators). Fast alle existieren identisch auf User-Level
(`~/.agents/skills/`) und sind dort gemeint; nur das git/gh/github-Set und
`blueprint` sind Repo-exklusiv. Ein ungebremster Mirror verwischt die Grenze
zwischen Projekt-Workflow-Skills und persoenlicher Bibliothek, macht
Skill-Diffs im Repo unuebersichtlich und riskiert Repo-Duplikate, die
divergieren, sobald eine Seite gepflegt wird.

Zugleich gilt der Operator-Auftrag aus der Session: fuer Projektarbeit
bevorzugt die Skills aus dem Repo (`PROJEKT-ROOT/.agents/skills/`) nutzen;
erst wenn dort nichts passt, auf User-Level zurueckgreifen.

## Entscheidung

1. **Repo-Scope:** `.agents/skills/` im Repo enthaelt nur
   - die Blueprint-Workflow-Skills (repo-owned: onboard, discovery, doctor,
     feature, implement, check, audit, complete, …),
   - das git/gh/github-Set (git-advanced-workflows, git-pr-workflows-*,
     github*, gitops-workflow),
   - Session-Skills ohne User-Level-Kopie (agents-md, analyze-project,
     brainstorming, session-docs-guardian, idea-refine,
     security-bluebook-builder).
2. **User-Level = persoenliche Bibliothek:** Alles, was dort schon liegt,
   wird nicht als Repo-Kopie gespiegelt. Duplikate wurden am 2026-09-29 aus
   dem Repo entfernt (Issue #61); `gm`/`gm-continue` bleiben als
   Evaluierungsgegenstand in Issue #20 auf User-Level.
3. **Fallback-Kette (bindend fuer Agenten):**
   Repo `.agents/skills/` → User-Level `~/.agents/skills/` → nur bei echter
   Notwendigkeit `~/.agents/skills/.disabled/`. Ein Re-Enable aus `.disabled/`
   wird im jeweiligen Issue dokumentiert, nie still vorgenommen.
4. **Safety-Regel fuer kuenftige Syncs:** Ein Repo-Skill-Ordner wird nur dann
   geloescht, wenn `~/.agents/skills/<name>/SKILL.md` existiert. Ordner ohne
   User-Level-Kopie bleiben im Repo (Beispiel: idea-refine,
   security-bluebook-builder).

## Konsequenzen

- Positive: klare Ownership (Projekt-Workflow vs. persoenliche Bibliothek),
  reviewbare Skill-Diffs, kein Duplikat-Drift.
- Negative: Ein Skill, der auf User-Level fehlt, muss explizit ins Repo —
  die Safety-Regel fängt das ab.
- Pflege: Neue Repo-Skills werden im README-Skills-Abschnitt registriert
  (Session-Docs-Guardian), neue User-Level-Skills nicht.

## Verwandtes

- ADR-005 (Mirror statt Move — Skills-Bibliothek) bleibt unberuehrt; dieses
  ADR schraenkt den Repo-Anteil ein.
- Issue #61 (Slice 2 des Struktur-Plans
  `docs/plan-2026-09-29-struktur-ordnung.md`), Issue #20 (gm-Evaluierung).
