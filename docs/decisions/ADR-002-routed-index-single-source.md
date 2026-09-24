# ADR-002: routed-Indexierung ueber einen einzigen, breiten Weg

## Status

Accepted

## Date

2026-09-24

## Context

routed indexiert Skills ueber mehrere Wege mit unterschiedlichen Ergebnissen:

| Weg | Ergebnis | Nutzung |
|-----|----------|---------|
| CLI `routed scan` | 972 Skills | `skills-sync.ps1` (PR #11) |
| MCP `scan_skills -workspace` | 2.843 Skills | MCP-Clients (Claude, Antigravity, Freebuff) |

Die Divergenz bedeutet: Wer nur das CLI-Hook laufen laesst, hat einen unvollstaendigen Index - semantische Suche (`route_skill`) findet Skills nicht, obwohl sie auf der Platte liegen. Wurzel vermutet (PR #11): `routed scan` erfasst `.agents\skills` nicht automatisch beim Environment-Scan.

Betroffene Consumer: `skills-sync.ps1`, der geplante Skills-Manager-Watcher (Issue #8), und jede Agent-Sitzung, die auf `route_skill` vertraut.

## Decision

1. **`scan_skills` (MCP/Workspace-Modus) ist der massgebliche Indexierungsweg.** Alle Automatisierung (`skills-sync.ps1`, spaeter der Skills-Manager-Watcher) ruft ausschliesslich diesen Weg oder das CLI-Aequivalent mit gleichem Umfang auf.
2. **`routed scan` (schmaler Environment-Scan) gilt als Legacy-Einstieg** und wird nicht mehr in Hook-Skripte eingebaut.
3. `skills-sync.ps1` wird auf den breiten Weg umgestellt (Folgearbeit Issue #15) und an den Install-Flow des Skills-Managers angebunden (Issue #17).
4. Die README-Skill-Architektur-Doku wird entsprechend aktualisiert (siehe Issue #15 Acceptance Criteria).

## Alternatives Considered

### Beide Wege parallel laufen lassen (Union)
- Pros: Redundanz, falls ein Weg Pfade uebersieht
- Cons: Zwei Wahrheiten, unklar welcher Index gerade gilt; doppelte Laufzeit bei 2.800+ Skills
- Rejected: Widerspruechliche Zaehler waren genau das urspruengliche Problem

### Nur CLI, MCP-Aufruf emulieren
- Pros: Keine MCP-Abhaengigkeit in Skripten
- Cons: Der CLI-Weg ist der lueckenhafte; das Problem wuerde konserviert
- Rejected: Richtungswechsel waere teurer als die Umstellung

### Eigene Index-DB neben routed
- Pros: Voller Kontrolle
- Cons: Duplizierte Semantik-Suche, Wartungsaufwand, routed ist dafuer gebaut
- Rejected: klare Verschwendung

## Consequences

- Skripte, die `routed scan` aufrufen, muessen umgestellt werden (Issue #15/#17)
- Die Skill-Zahl nach einem Sync-Lauf wird vorhersehbar (~2.843+ je nach Bestand)
- Falls routed den Workspace-Modus aendert, betrift das alle Automatisierung - der Test dafuer gehoert in die Skills-Sync-Idempotenz-Pruefung (Issue #17)

## Related

- Issue #15 (Divergenz klaeren und umstellen)
- Issue #17 (skills-sync automatisiert anbinden)
- PR #11 (using-skills, Quelle der Beobachtung)
