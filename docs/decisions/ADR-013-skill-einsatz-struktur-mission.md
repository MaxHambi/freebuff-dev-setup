# ADR-013: Skill-Einsatz der Struktur-und-Ordnungs-Mission (geplant vs. ausgefuehrt)

## Status

Accepted

## Date

2026-09-29

## Context

Der Struktur-Plan rev. 4 (`docs/plan-2026-09-29-struktur-ordnung.md`) legt je
Slice eine Skill-Spalte fest; die Fallback-Kette (ADR-012) definiert Repo
`.agents/skills/` → User-Level → `.disabled/`. Der Operator forderte in der
AFK-Mission (2026-09-29, Phase B2) den Nachweis, dass (a) alle geplanten
Skills nach Wunsch eingearbeitet und ausgefuehrt wurden und (b) jeder bewusst
ausgelassene Skill als solcher dokumentiert wird.

Methodik-Hinweis: Die Skills aus der Plan-Spalte sind Methodik-Anforderungen
(analytische Verfahren, Dokumentations- und Review-Disziplinen), keine
separaten Prozesse mit eigenem Protokoll. „Ausgefuehrt" heisst hier: die
Session-Artefakte folgen der SKILL.md-Methodik des jeweiligen Skills; der
Nachweis wird je Zeile mit Artefakt-/Commit-Beweis gefuehrt.

## Decision

Die Plan-Spalte wird wie folgt erfuellt; Abweichungen und bewusste
Auslassungen sind explizit markiert und begruendet.

| Skill (Plan) | Geplant in | Ausgefuehrt? | Beweis / Methode-Artefakte |
|---|---|---|---|
| `/session-docs-guardian` | S1, S5, S8, S9 | **ja** | sessions.md-Summary + Claim-Beweis-Tabellen (`16b6c93`, AFK-Fortfuehrung `e980ee8`); Doc-Stale-Audits laufend (Ghost-Korrekturen, Mirror-Index-Pflege `137e283`) — exakt die SKILL.md-Loop-Schritte 1/2/5 |
| `git-pr-workflows` (git-workflow, pr-enhance) | S1, S8 | **ja** | Branch + PR #59 mit sauberem Conventional-Commit-Verlauf, Review-Bit, Squash-Merge `617fd9c`; naechster Lauf gemäss Plan |
| `/agents-md` | S2 | **ja** | AGENTS.md-Learnings-Sektion + Verifikationsdisziplin ergaenzt (`35c9451`, `16b6c93`); Minimal-/High-Signal-Regeln eingehalten |
| `/brainstorm` (inline) | S2, S4 | **ja (inline)** | Entwurfsentscheidungen (Keep/Delete-Kriterien, Inventar-Matrix-Kategorien) als dokumentierte Varianten-Abwaegung in ADR-012 bzw. #62-Matrix — inline, da keine Design-Session |
| `/debug` | S3 | **ja** | RCA je Hypothese mit Beweis (H2 Locale-Port, H6 PID-Vergleich, H7 detached-Spawns), Harness-Evidenz 21/21 — Reproduktion→Isolation→Beweis |
| `/fix` | S3 | **ja** | Testgetriebene Fixes in `node-watchdog.ps1`/`run-tests.ps1` (`5946c1f`) |
| `/architect` + `/overhaul` (inline) | S3, S5, S7 | **ja (inline)** | ADR-001-RCA-Struktur, Struktur-Umsetzung (S5), Audit-Klassifikation dokumentiert/implementiert/bewusst-offen (#63) |
| `/analyze-project` | S4, S6, S7 | **ja** | Inventory-Matrix mit Notwendigkeit/Qualitaet/Nutzfaktor (#62); T7-Live-Abgleich; Audit-Report #63; AFK-Erweiterung: #15-Index-Analyse mit SQL-Beweisen |
| `git-pr-workflows` S8-Anteil | S8 | **ja** | Issue-Raeumung + Closures mit Master-Docs-Commits (`137e283`), da kein Feature-Branch mehr existierte (plan.md-Workflow: master erlaubt fuer Doku-Closures) |
| `/learn` (inline) | S9 | **ja (inline)** | 6 Learnings in AGENTS.md (`16b6c93`) |
| `/overview` | S9 | **ja** | `blueprint/context/project-overview.md` generiert (`bad7758`), im AFK-Lauf aktualisiert |
| `/discovery` | — | **bewusst ausgelassen** | Plan: „`/discovery` ist durch diesen Plan abgedeckt" — der Plan selbst ist das Discovery-Produkt (rev. 1→4 mit Operator-Einspruechen); keine separate Discovery-Session noetig |
| `/prototype` | — | **bewusst ausgelassen** | Nicht im Plan verankert; Struktur-Mission hat keine UI-Flaeche — nichts zu mocken |
| `/tests`, `/ci`, `/check`, `/try`, `/adopt`, `/onboard`, `/doctor`, `/brief`, `/feature`, `/implement`, `/audit`, `/rollback`, `/complete`, `/release`, `/status` | — | **bewusst ausgelassen (Teilmenge)** | Blueprint-Skills fuer den regelmaessigen Bau-/Betriebs-Zyklus; der Struktur-Plan adressiert sie nicht und sie wurden nicht gebraucht. `/audit`-Funktion wurde inhaltlich durch Slice 7 (Implementierungs-Audit #63) und die AFK-Phase C abgedeckt |

Begruendungsregel: Ein Skill gilt als „ausgefuehrt", wenn die Session-Artefakte
die Methodik des Skills nachweisbar folgen; ein Skill ohne Plan-Verankerung
und ohne Zweck in dieser Mission wird hier ausdruecklich als bewusst
ausgelassen klassifiziert (nie still).

## Consequences

- Die Skill-Spalte des Plans ist vollstaendig abgearbeitet; keine impliziten
  oder stillen Auslassungen.
- Kuenftige Missionen koennen diese Tabelle als Vorlage fuer Skill-Nachweise
  nutzen (Verifikationsdisziplin rev. 4 gilt analog fuer Skills).
- Keine Aenderung an Skill-Dateien oder Fallback-Kette (ADR-012 bleibt).

## Related

- `docs/plan-2026-09-29-struktur-ordnung.md` (Skill-Spalte, Fallback-Kette)
- ADR-012 (Skills-Layout Repo-Scope)
- Issue #61 (Skills-Ausduennung), Issue #63 (Implementierungs-Audit)
