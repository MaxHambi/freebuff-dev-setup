# ADR-008: MemPalace-Anbindung ohne MCP-Consent — CLI-Fallback und Diagnose-Gate

## Status

Accepted

## Date

2026-09-26

## Context

Die `mempalace_*`-MCP-Tools (45 Tools) sollten in Freebuff über die
projekt-lokale `.mcp.json` registriert werden. Stand nach dem
Freebuff-Restart:

- Die Tool-Registrierung listet nur rayrun, synapse, routed, claimidx —
  kein mempalace.
- Ursache: `~/.freebuff/mcp.json` (Consent-State, app-intern, Hash-Keys)
  enthält keinen mempalace-Eintrag; der Consent-Prompt wurde nie bestätigt.
- Der Consent-Prompt existiert nur in der Freebuff-UI — kein CLI-/Config-
  Weg (Issue #28, `ready-for-human`).
- Die Binary selbst ist gesund (STDIO-Smoke: mempalace 3.10.0, 45 Tools);
  die CLI deckt Suche/Mining/Logstream vollständig ab.

Agenten dieser Session brauchten trotzdem: Suche (Recall-Protokoll),
`add_drawer` (3 Decision-Drawers gefiled), `delete_by_source`
(Junk-Registry-Eintrag bereinigt).

## Decision

1. **CLI-Fallback ist der sanktionierte Betriebs-Pfad:** `mempalace
   search` / `mine` / `logstream` laufen über die CLI; strukturierte
   Tool-Aufrufe (`add_drawer`, `delete_by_source`) über STDIO-JSONRPC
   direkt gegen `mempalace-mcp.exe` — gleiche Binary, gleicher
   Consent-Nachvollzug wie ein MCP-Client.
2. **Agent-Identity verbindlich:** `maxhambi:freebuff:freebuff-dev-setup`
   als `added_by`/`created_by` — auch auf dem STDIO-Pfad. Die
   Impersonation-Regel des Shared-Brain-Protokolls gilt unverändert.
3. **Diagnose-Gate als Script:** `memory-ingest/check-mempalace.ps1` prüft
   Consent-State, Binary-Smoke (30-s-Timeout) und Palast-Suche in einem
   Lauf. Exit 0 = grün, 1 = harter Fehler, **2 = nur Consent fehlt**
   (erwarteter Zustand bis #28, kein Fehlerfall).
4. **Consent bleibt menschliche Aufgabe (#28):** Keine Versuche, den
   app-internen Approval-State (`~/.freebuff/mcp.json`, Hash-Keys) manuell
   zu manipulieren.

## Alternatives Considered

### Consent-State manuell in ~/.freebuff/mcp.json schreiben
- Pros: MCP-Tools sofort live
- Cons: App-internes Format (`launchHash`, `manifestHash`,
  `approvedManifest`); ein manipulierter State kann den Consent-Flow
  dauerhaft korrumpieren und umgeht den vorgesehenen User-Consent
- Rejected: Security- und Stabilitätsrisiko ohne Gegenwert

### Auf die MCP-Tools warten, bis der Consent bestätigt ist
- Pros: Kein Zweitpfad
- Cons: Blockiert alle Gedächtnis-Operationen (Recall-Protokoll verlangt
  Suche vor Antworten); unbestimmte Wartezeit
- Rejected: Der Palast gehört der Session, nicht der Transport-Ebene

### MCP light (mempalace-light-mcp, 3 Tools) prüfen
- Pros: Kleinere Tool-Fläche (Schema-Tokens)
- Cons: Löst das eigentliche Problem (fehlender Consent) nicht; 45 Tools
  sind akzeptabel
- Rejected: Optimierung an der falschen Stelle (mit Issue #31 im Backlog)

## Consequences

- Alle Gedächtnis-Operationen funktionieren heute; sobald #28 bestätigt
  ist, wird der STDIO-Pfad obsolet (Issue #29 verifiziert die Live-Tools).
- STDIO-Aufrufe müssen die Identity-Regeln respektieren — Agenten fügen
  `added_by` selbst bei.
- Exit 2 des Diagnose-Scripts ist bis #28 der Normalzustand; der
  Memory-Ingest (ADR-007) hängt nicht davon ab.
- Der Registry-Junk-Fall (State-Datei im Mining-Korpus) ist dokumentiert
  und bereinigt; Prävention durch State-Lage neben dem Export-Ordner.

## Related

- Issue #28 (Consent, `ready-for-human`), Issue #29 (Live-Verifikation
  nach Consent), Issue #31 (Gedächtnis-Ergänzung, light-MCP-Prüfung)
- ADR-007 (Memory-Ingest-Betrieb)
- ADR-009 (`.mcp.json` bleibt projekt-lokal — Consent-Mechanik)
- Mem-Palace.md (FAQ „Freebuff sieht mempalace nicht", Diagnose-Script)
