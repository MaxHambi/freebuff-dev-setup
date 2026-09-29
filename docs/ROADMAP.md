# ROADMAP — offene Arbeiten in bester Abarbeitungsreihenfolge

> Erstellt 2026-09-29 (Struktur- und Ordnungs-Mission, Slice 8). Reihenfolge
> nach Abhaengigkeiten und Risiko: erst Vertrauen in die Daten, dann
> Automatisierung darauf. Bei neuen Erkenntnissen diese Datei aktualisieren
> (Issue-first: arbeite je Posten auf seinem GitHub-Issue).

## 1. Routed-Index-Divergenz klaeren (#15) — **nächster Schritt**

**Ziel:** CLI `scan` (972 Skills) und MCP `scan_skills` (2843) zaehlen
unterschiedlich; die Ursache (Container-Unterschiede? Duplikat-Roots?)
wird geklaert und der massgebliche Index (ADR-002: MCP `scan_skills`)
valide gemacht.

**Warum zuerst:** Beide Folge-Posten bauen auf einem vertrauenswuerdigen
Index auf; ohne Klarung riskiert jede Sync-/Scan-Automatisierung, Muell zu
verstetigen.

**Abhaengigkeiten:** keine. **Groesse:** mittel (Untersuchung + Fix +
Verifikationslauf).

## 2. SkillSpector-Integration (#19)

**Ziel:** Risk-Scan (Security-Score, Risk-Klassen) als optionale Quelle in
die Analyse-CLI des skills-manager integrieren; TDD mit Test-Seams nach
ADR-004.

**Warum danach:** Die Analyse-CLI klassifiziert heute stale/incompat/needs-
setup; der Risk-Scan erganzt die Sicherheitsdimension — aber nur sinnvoll,
wenn der Scan-Index (Posten 1) stimmt.

**Abhaengigkeiten:** Posten 1. **Groesse:** mittel-gross (TDD, externe
Anbindung).

## 3. Skills-Sync automatisieren (#17)

**Ziel:** Anbindung und Idempotenz des Skill-Syncs festschreiben (Snapshot-
Diff via `skills-sync.ps1`, Registrierung via `routed scan`; ADR-002/012
beachten).

**Warum danach:** Automatisierung erst, wenn Index (Posten 1) und
Klassifizierung inkl. Risk (Posten 2) stehen — sonst automatisiert man
falsche Daten.

**Abhaengigkeiten:** Posten 1 + 2. **Groesse:** klein-mittel.

## 4. gm/gm-continue-Nachfolge (#20-Nachfolge)

**Ziel:** Bei erstem echten Einsatz der gm-Skills die Eval-Fragen
(Supply-Chain-Pinning, Konventions-Konflikte) beantworten; bei hartem
Konflikt Issue neu oeffnen und ggfs. aus der User-Level-Bibliothek
entfernen.

**Abhaengigkeiten:** keiner (Einsatz-getrieben). **Groesse:** klein
(nach Einsatz).

## 5. Session-Doku-Hook entscheiden (#62-Follow-up)

**Ziel:** `session-docs-guardian`-Hook `session-end.ps1` registrieren
(Anleitung: `~/.agents/skills/session-docs-guardian/hooks/register-hook.md`)
oder bewusst streichen und die Hook-Landkarte bereinigen. Operator-Entscheid.

**Abhaengigkeiten:** keiner. **Groesse:** klein.

## 6. Nach dem Merge von PR #59 (eigener kleiner Lauf)

- #63 (Audit) und #62 (Inventar) schliessen; danach die im Slice-8-Issue
  (#64) bestatigten Loesch-Kandidaten mirror-first loeschen
  (#21–#26, #36–#43; #28–#32/#53/#54/#56 erst nach PR-#59-Merge).
- Issue-Mirror-Index (`docs/issues/README.md`) final abgleichen.

## Nicht-Roadmap (bewusst)

- Denylist-Write-Roundtrip (Closeout-Slice 7): von Operator vertagt, kein
  Roadmap-Posten bis zur Revokation.
- opentui-Dependency: bleibt bis Backlog-Entscheid (ADR-006-Kontext).
