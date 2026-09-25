# Issue-Fibel

Kurzguide passend zu [issue-tracker.md](agents/issue-tracker.md) und
[triage-labels.md](agents/triage-labels.md) - analog zur Worktree-Fibel.
Frage der Fibel: Welches Issue-Layout wann, welche Labels, wie geht die
Arbeit ueber (Handoff)?

## 1. Wann wird ein Issue angelegt?

Default ist **Issue-first**: Jede Arbeit mit mehr als einem Commit bekommt
vorher ein Issue (gleiche Regel wie ADR-003 fuer Worktrees). Ein Issue
anlegen bei:

| Bedingung | Beispiel |
|-----------|----------|
| Neues Feature/Fix mit Akzeptanzkriterien | #19 (SkillSpector-Integration) |
| Review-Finding, das nicht sofort gefixt wird | Stopword-Heuristik im check-changelog.ts (aus dem Review-Swarm) |
| Begleit-Issue zu einer ADR-Verifikation | #14 (ADR-001-Closure) |
| Evaluierung/Fremd-Tool-uebernahme | #20 (gm-Skill) |

**Kein eigenes Issue** bei Trivialitaeten, die im selben Zug geliefert
werden (Ein-Zeilen-Doku, Tippfehler) - Conventional-Commits- und
CHANGELOG-Regeln gelten trotzdem.

## 2. Layouts (drei Kanonenformen)

| Typ | Aufbau | Beispiele |
|-----|--------|-----------|
| **Umbrella/PRD** | Problem Statement, User Stories (nummeriert, checkbar), Implementation/Testing Decisions, Out of Scope | #1 |
| **Slice/Implementierung** | Parent, What to build, Acceptance Criteria (einzelcheckbar), Blocked by (echte Nummern) | #2-#10 |
| **Nacharbeit/Evaluierung** | Ausgangslage (verifizierte Fakten), Warum, Checkliste, Nicht-Ziele, Vorgehen | #14-#17, #19, #20 |

Regeln:

- Titel = Typ + Scope (`Slice 5: Mirror-Gruppierung - ...`, `feat: ...`).
- Abhaengigkeiten als **echte Issue-Nummern** - deshalb Blocker zuerst
  anlegen (`gh issue create` in Abhaengigkeitsreihenfolge).
- PRD-/Slice-Bodies werden unter `skills-manager/docs/issues/` gespiegelt
  (Repo ist Quell der Wahrheit fuer die Doku, GitHub ist der Tracker).

## 3. Labels (das Status-Spiel)

Die fuenf kanonischen Labels (Vokabular: `docs/agents/triage-labels.md`):

| Label | Wann | Wer setzt |
|-------|------|-----------|
| `needs-triage` | Frisch angelegt, noch nicht bewertet | Anlegender (Default) |
| `needs-info` | Wartet auf den Reporter (Frage im Body) | Triage |
| `ready-for-agent` | Vollstaendig spezifiziert, AFK-faehig | Maintainer nach Review |
| `ready-for-human` | Braucht menschliche Umsetzung (Entscheidung, Konto, Hardware) | Triage |
| `wontfix` | Wird nicht umgesetzt - **immer mit Grund im Schliess-Kommentar** | Maintainer |

Label-Wechsel = Statusuebergang: `needs-triage` → `needs-info` →
`ready-for-agent` → (Arbeit, PR) → geschlossen. `ready-for-agent` heisst:
alle Fakten stehen im Body, keine muendlichen Zusaetze - ein AFK-Agent
muss daraus allein arbeiten koennen.

## 4. Handoff-Regeln

- **Issue → Agent:** nur mit `ready-for-agent`; der Agent zitiert die
  Acceptance Criteria im PR und liefert `Closes #<n>` im PR-Body.
- **Agent → Issue:** Findings und ehrliche Reste landen als Kommentar am
  Issue (Beispiel: #7-Closure mit unerreichtem Perf-Ziel) - nie still
  schmaelern, nie Criteria im Nachhinein verbiegen.
- **Issue → Issue:** Neue Erkenntnis waehrend der Arbeit wird ein
  Folge-Issue mit Verweis (Beispiel: #1 verweist auf #19), statt den Body
  zu erweitern.
- **Schliessen ist nie still:**
  - `completed` - realisiert, mit PR-Referenz; unerreichte Ziele benennen
  - `not planned` + `wontfix` - mit Ersatz-/ADR-Verweis (Beispiel:
    #3-#10 → ADR-006, skill-manager + SkillSpector)
  - Umbrella veraltet - Grund + Nachfolge-Doku verlinken (#1 → ADR-006)
- **Reopen statt Neu** bei unvollstaendiger Closure - Nummern sind Adressen.

## 5. Lifecycle im Schnelldurchlauf

1. Anlegen (Layout nach Abschnitt 2, Blocker zuerst)
2. `needs-triage` setzen (PRDs/Evals des Maintainers: direkt Final-Label)
3. Spezifizieren → `ready-for-agent` (oder `ready-for-human`/`wontfix`)
4. Arbeit: Feature-Branch, `Refs #<n>` im Commit-Body,
   `Closes #<n` **nur** im PR-Body
5. Merge schliesst; Reste → Kommentar oder Folge-Issue
6. Body-Mirror unter `skills-manager/docs/issues/` nachziehen

## 6. Regeln im Schnelldurchlauf

1. Issue zuerst, Arbeit danach (Issue-first)
2. Ein Issue = ein Thema; Umbrella nur fuer Planungssichten
3. Acceptance Criteria einzeln checkbar formulieren
4. Labels sind der Zustand - kein Body-Text "Status: fertig"
5. Schliess-Kommentar erklaert immer das Warum (mit Verweis)
6. Worktree-Bedarf entscheidet ADR-003 + Worktree-Fibel, nicht das Issue

## 7. Zustandscheck (ein Befehl je Frage)

| Frage | Befehl |
|-------|--------|
| Was ist offen? | `gh issue list --state open` |
| Was ist AFK-faehig? | `gh issue list --label ready-for-agent` |
| Details eines Issues? | `gh issue view <n>` |
| Blockiert was wen? | `gh issue view <n> --json body -q .body` (Blocked by) |
| Was wurde wie geschlossen? | `gh issue list --state closed --limit 20` |
