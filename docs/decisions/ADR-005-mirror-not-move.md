# ADR-005: Skills-Bibliothek als Mirror, nicht als Umbau

## Status

Accepted

## Date

2026-09-24

## Context

Die persoenliche Skills-Bibliothek (`~/.agents/skills/`, 1.800+ Ordner) ist ein flacher Berg und wird laufend manuell aufgeraeumt. Drei Ansaetze standen zur Auswahl, wie der Skills-Manager ihnen thematische Struktur geben soll:

1. In-place umbauen (Skills in Gruppen-Unterordner verschieben)
2. Mirror-Ordner (`~/.agents/skills-org/<gruppe>/`) als thematische Kopie
3. Nur virtuelle Gruppierung im Index, ohne Datei-Kopie

Entscheidungsrelevante Fakten:

- Tools wie Antigravity pflegen ein Install-Manifest (`.antigravity-install-manifest.json`) mit Pfadeintraegen; ein in-place Umbau wuerde es veralten lassen
- routed indexiert die Original-Pfade; Verschieben macht Neu-Indexierung unumgaenglich
- Die Bibliothek ist persoenlicher Zustand - ein Fehler im Umbau ist teuer
- Die Parallel-Sitzung (using-skills) hat gezeigt: mehrere Akteure fuehlen sich fuer denselben Ordner zustaendig

## Decision

**Mirror-Strategie (Option 2), mit expliziten Garantien:**

1. Die Original-Bibliothek wird vom Skills-Manager **nie** veraendert - keine Verschiebung, kein Umbenennen, kein Loeschen
2. `~/.agents/skills-org/` enthaelt die thematische Kopie (Gruppen via Keyword-Buckets + routed-Fallback), gebaut per Dry-Run-Report und `copy-manifest.json`
3. Der Mirror wird **inkrementell** nachgezogen (Delta-Sync), nicht per Voll-Kopie
4. Install in Projekte kopiert ebenfalls (nie verschieben); Konflikte werden gemeldet statt still ueberschrieben
5. Aufraeumen (Loeschen, Umbenennen, Deprecate) bleibt menschliche Arbeit im Original - der Manager dokumentiert nur (Badges, Reports)

## Alternatives Considered

### In-place Gruppen-Unterordner
- Pros: Eine einzige Wahrheit, keine Duplizierung (89 MB), Mirror-Pflege entfaellt
- Cons: Manifest-Bruch, routed-Neuindexierung, kein Rollback, Risiko beim persoenlichen Bestand
- Rejected: Der Schaden eines Fehlers ist nicht wiederherstellbar; Duplicate-Speicher (89 MB) ist trivial dagegen

### Nur virtuelle Gruppierung (Index)
- Pros: Keine Kopien, immer aktuell
- Cons: Im Datei-Explorer bleibt der flache Berg; Tools ausserhalb der TUI sehen nichts
- Rejected: Der Mirror ist explizit auch fuer Explorer-Nutzung und tool-uebergreifendes Surfen gewollt

### Symlink-Mirror statt Kopie
- Pros: Kein Speicherverbrauch, immer synchron
- Cons: Symlinks auf Windows brauchen Admin/Developer-Mode, manche Tools folgen ihnen nicht, `fs.cp` auf Links ist fehleranfaellig
- Rejected: Portabilitaet und Robustheit wiegen den Speichervorteil nicht

## Consequences

- 89 MB zusaetzlicher Plattenplatz (akzeptiert)
- Mirror-Sync muss in den Watcher integriert werden (Issue #8) - der Mirror ist nur so gut wie sein letzter Sync
- Bei Konflikt Original vs. Mirror gewinnt immer das Original; der Mirror ist als Sicht, nicht als Bestand definiert
- Das Copy-Manifest ist die Basis fuer spaetere Differenzpruefungen (Mirror-Drift-Detektion, falls noetig)

## Related

- PRD #1 (User Stories 16-19, Implementation Decisions)
- Issue #6 (Mirror-Gruppierung - Implementierung)
- Issue #8 (Watcher & Mirror-Sync - Inkrementalitaet)
- ADR-003 (Worktree-Strategie, gleicher Grundgedanke: Original schuetzen, Arbeit isolieren)
