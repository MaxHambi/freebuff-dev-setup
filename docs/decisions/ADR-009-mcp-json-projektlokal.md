# ADR-009: `.mcp.json` bleibt projekt-lokal — Ignore statt Team-Commit

## Status

Accepted — der tatsächliche Freigabe-Weg (globaler Pfad `~/.agents/mcp.json`
via Freebuff-UI, ADR-010) hat den hier beschriebenen Projekt-Consent-Fluss
inzwischen ersetzt; die Ignore-Entscheidung für `.mcp.json` bleibt unverändert
gültig.

## Date

2026-09-26

## Context

Die Freebuff-MCP-Registrierung `.mcp.json` (mempalace über den
maschinenspezifischen Pfad `C:\Users\Max Hambi\.local\bin\mempalace-mcp.exe`)
war bereits getrackt. Die offene Frage aus dem FAQ: Team-Commit oder lokale
Datei?

Fakten:

- Einzelnutzer-Rechner; Remote ist ein privates Repo (Single-Committer).
- Consent-Bindung: Der Approval-State (`~/.freebuff/mcp.json`) keyed per
  Hash über die Server-Konfiguration — eine geänderte `.mcp.json` (z. B.
  andere Pfade auf einem zweiten Rechner) invalidiert den Consent und
  erzwingt eine neue Freigabe.
- Getrackte Dateien ignorieren `.gitignore` nicht — die Regel allein hätte
  nichts bewirkt.

## Decision

1. **`.mcp.json` wird aus dem Index entfernt** (`git rm --cached`) und in
   `.gitignore` aufgenommen; die lokale Datei bleibt (Freebuff liest sie
   weiter).
2. **Keine Vorlage im Repo** (`.mcp.json.example` entfällt bewusst): Der
   Inhalt sind wenige Zeilen mit maschinenspezifischen Pfaden; die Doku
   (Mem-Palace.md, ADR-007/008) beschreibt das Setup.
3. **Neue Maschinen:** `.mcp.json` einmalig lokal anlegen, Consent in der
   Freebuff-UI erteilen (Muster aus Issue #28), dann mit
   `memory-ingest/check-mempalace.ps1` verifizieren.

## Alternatives Considered

### Im Team-Repo committen
- Pros: Klonen = fertige MCP-Registrierung
- Cons: Maschinenspezifische Pfade in Git; Consent-Invalidierung bei
  Pfadabweichungen; bei Team-Zuwachs leakt der Benutzerpfad
- Rejected: Für einen Einzelnutzer ohne Gegenwert, mit Pfad-/Consent-Reibung

### `.mcp.json.example` als Vorlage committen
- Pros: Onboarding-Hilfe
- Cons: Zwei Quellen der Wahrheit für wenige Zeilen; Verwechslungsgefahr
  zwischen Beispiel und aktiver Datei
- Rejected: Die Doku reicht aus (aktuell Single-User)

### MCP-Server global statt projekt-lokal registrieren
- Pros: Keine Repo-Datei nötig
- Cons: mempalace erschiene auch in Projekten ohne Palast-Bezug; der
  projekt-lokale Scope ist das kleinere Übel
- Rejected: Projekt-Scope behalten

## Consequences

- Das Repo ist klonbar ohne gebrochene Pfade; die Datei lebt nur auf
  Maschinen, die sie brauchen.
- Bei Consent-Änderungen (z. B. neuer Binary-Pfad) gilt: `.mcp.json`
  ändern → neuer Consent-Prompt in der Freebuff-UI (kein Workaround).
- Falls später Team-Nutzer dazukommen: Diese Entscheidung superseden
  (Vorlage + Onboarding-Doku neu denken).

## Related

- Issue #28 (Consent-Muster für neue Maschinen)
- ADR-008 (Consent-Mechanik, Diagnose-Gate)
- Mem-Palace.md (FAQ, Entscheidung 26.09.2026)
