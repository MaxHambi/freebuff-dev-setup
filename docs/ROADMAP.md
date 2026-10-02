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

**Stand 2026-09-29 (AFK-Analyse, Befunde auf #15):** Divergenz mechanistisch
erklaert — der CLI-Scan sieht die User-Bibliothek nicht (`.agents\skills`
steht in keiner Environment-Pfadliste); der alte 2867-Index enthielt
Stale-/Doppel-Anteile (~218 Rows: geloeschtes `.claude\skills`, Alt-Pfad
`tools-entwicklung`, Marketplace-Embedded-Dopplung). Offen bleibt die
Discovery-Luecke der aktuellen routed-Version (v1.6.95): 1968 SKILL.md auf
Disk vs. 398 discovered per MCP-Scan. Betriebsrisiko live bewiesen:
`routed scan` prunte 2512 Eintraege in einem Lauf — **Empfehlung:
`skills-sync.ps1` bis zur Umstellung stilllegen** (→ #17). Fix-Kriterien:
Index-Zahl == Disk-Zahl je Root; dauerhafter Disk-vs-Index-Check (#17).

**Stand 2026-09-30 (Fix-Lauf, Operator anwesend):** Root-Cause auf
Code-Ebene bestätigt (routed v1.6.95, Quelltext-Analyse + Live-Zahlen):
(1) `~/.agents/skills` fehlt im Detector-Default — Scanner 396 gegen
2373 SKILL.md auf Disk (355 plugins + 40 Repo + 1 custom); (2) auch mit
angemeldetem Root findet der Scanner nur 43 der 1968 User-Lib-Skills:
`crawlDirectory` stoppt die Rekursion an Ordnern mit eigener SKILL.md
(Container-Bibliotheken bleiben unsichtbar); (3) CLI-`scan` pruned global
(`removeMissingSkills`), MCP-`scan_skills` ist upsert-only (live bewiesen:
Index blieb nach Scan bei 436). **Umgesetzt:** `skills-sync.ps1`
stillgelegt (C1, Re-Enable-Kriterien im Dateikopf), `ROUTED_CONFIG_PATH`
auf User-Level gesetzt (`~/.agents/routed-environments.json`, `setx` —
aktiv für neue Prozesse). Upstream: [bshea-1/Routed#2](https://github.com/bshea-1/Routed/issues/2).
Offen bis routed-Fix: Index == Disk je Root (voller Aushang der
User-Lib + Stale-Bereinigung 40 Rows); Disk-vs-Index-Check → #17.

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

**Ziel:** Anbindung und Idempotenz der Index-Registrierung festschreiben
(Registrierung ausschliesslich via MCP `scan_skills`, upsert-only;
dauerhafter Disk-vs-Index-Check; `skills-sync.ps1` bleibt stillgelegt,
bis routed Prune-/Discovery-Fixes bringt — siehe Posten 1 und
[bshea-1/Routed#2](https://github.com/bshea-1/Routed/issues/2); ADR-002/012
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

## 7. Session-Restpunkte 2026-10-01 (#68)

**Ziel:** Drei bewusst offengebliebene Restpunkte der Fenster-Flash-
Session abarbeiten (Checkliste auf #68): Task-Fail-Alerting (taeglicher
Check aller eigenen Tasks, Warn-Event bei `LastTaskResult` ungleich 0),
agenttrace-Baseline schaerfen (`MinHealth` 70 in
`scripts/agenttrace-audit.ps1` anhand gesammelter Berichte anheben) und
codebuff-team-Spur in gepushten Commits entfernen (reiner Operator-
Entscheid: History-Rewrite + Force-Push vs. GitHub Support).

**Abhaengigkeiten:** keine. **Groesse:** klein-mittel; je Punkt eigener
Branch/PR (ADR-003), Details und Nicht-Ziele auf #68.

## 5. Session-Doku-Hook entscheiden (#62-Follow-up) — ✅ entschieden 2026-09-29

**Entscheid (Operator, AFK-Mission 2026-09-29):** Hook **bewusst nicht
registriert**. Die Hook-Landkarte (README) ist bereinigt; der End-of-Session-
Doku-Audit laeuft skill-getrieben im Session-Closeout (session-docs-guardian
als Skill, nicht als Hook). Anleitung zur spaeteren Registrierung bleibt
erhalten: `~/.agents/skills/session-docs-guardian/hooks/register-hook.md`.

## 6. Nach dem Merge von PR #59 — ✅ erledigt 2026-09-29 (AFK-Mission)

- PR #59 gemerged (`617fd9c`); 22 Loesch-Kandidaten mirror-first geloescht
  (Los A + Los B), Mirror-Tombstones `sha256:gone` gestempelt,
  `mirror-sync -Check` gruen.
- Issue-Mirror-Index (`docs/issues/README.md`) abgeglichen (Zeilen
  #61–#64 ergaenzt, Tombstone-Zeilen umgestellt).
- Closures #62/#63/#64 mit Abschlusskommentaren (siehe Issues).

## Nicht-Roadmap (bewusst)

- Denylist-Write-Roundtrip (Closeout-Slice 7): von Operator vertagt, kein
  Roadmap-Posten bis zur Revokation. **Update 2026-09-30:** Roundtrip lief
  im AFK-Mission und fand den echten Bug #65 — dieser ist gefixt und live
  bewiesen (Report-Durchgang 2026-09-30); Posten damit erledigt.
- opentui-Dependency: bleibt bis Backlog-Entscheid (ADR-006-Kontext).

## Raeumungs-Legende

- **2026-09-30 (C7):** 12 weitere Issues geloescht (#1–#10 PRD/Slices,
  #34/#35 Wegwerf) — 38 Mirror-Dateien sind damit durchgehend die Quelle
  fuer alle geloeschten Issues (`sha256:gone`-Header, Mirror-Index
  vollstaendig). Traeger-Historie lebt in den Mirrors und in
  `skills-manager/docs/issues/`.
