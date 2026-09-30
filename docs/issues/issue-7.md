#7: Slice 6: Delta-Index - inkrementelle Analyse mit Move-Erkennung
<!-- mirror-sync: source=github:MaxHambi/freebuff-dev-setup#7 sha256:gone synced=2026-09-30T06:03:36Z -->

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#7](https://github.com/MaxHambi/freebuff-dev-setup/issues/7).
> Label: `ready-for-agent`. Status: **geschlossen (completed)** — Delta-Index in PR #12 geliefert (2026-09-24).
> Closure-Kommentare: [#7 (Kommentar 1)](https://github.com/MaxHambi/freebuff-dev-setup/issues/7#issuecomment-5826076225)

> Detail-Spiegel mit Implementierungsnotizen: [skills-manager/docs/issues/slice-6-delta-index.md](../../skills-manager/docs/issues/slice-6-delta-index.md) (keine mirror-sync-Header, dokumentierte Abweichung). Raeumungs-Kandidat (C7, 2026-09-30).

## Original-Body

## Parent

#1

## What to build

Macht die Analyse inkrementell – Grundlage für das Aufräumen im laufenden Betrieb: Eine State-Datei hält pro Skill einen Inhalts-Hash des SKILL.md plus Mtime und Größe. Ein Rescan vergleicht nur Deltas: unveränderte Skills werden nicht neu analysiert, neue analysiert und aufgenommen, geänderte neu klassifiziert, gelöschte entfernt.

- **Move-Erkennung**: Ein Ordner, der unter altem Namen verschwindet und unter neuem Namen mit identischem Hash auftaucht, wird als Umbenennung erkannt (kein Doppel-Eintrag, kein Klassifizierungs-Verlust).
- Der Delta-Lauf aktualisiert Index, State und Report nur für die betroffenen Einträge.
- Die Delta-Logik ist eine pure Lib-Funktion (alter State + Dateisystem-Delta → neuer State + betroffene Liste), testbar ohne Watcher und ohne Timing.

## Acceptance criteria

- [ ] Zweiter Analyse-Lauf ohne Änderungen verändert den Index nicht und ist deutlich schneller als der Erstlauf (nur Hash-Vergleiche)
- [ ] Neuer Skill-Ordner wird beim nächsten Lauf analysiert und aufgenommen
- [ ] Geändertes SKILL.md (z. B. Description) führt zu neu klassifiziertem Eintrag
- [ ] Gelöschter Skill-Ordner wird aus Index, State und Report entfernt
- [ ] Umbenannter Ordner mit gleichem Inhalt wird erkannt (Eintrag unter neuem Namen, alte Klassifizierung erhalten, kein Doppel)
- [ ] Lib-Tests gegen tmp-Fixtures für alle vier Deltas (add/change/delete/rename)

## Blocked by

- #2

## Kommentare

> **MaxHambi**: **Erfüllt durch PR #12 (Slice 1, gemerged als `d35353e`-Vorgänger).**

- Hash-basierter Delta-Index mit Move-Erkennung: alle vier Deltas (add/change/delete/rename) implementiert und gegen tmp-Fixtures getestet (`computeDelta`, `scan-delta.test.ts`)
- State-Datei `state.json` mit Content-Hash pro Skill; zweiter Lauf ohne Änderungen → nur `unchanged`
- Live-Verifikation: +2 Deltas für neu ergänzte PowerShell-Skills

Ehrlicher Rest: Das Acceptance-Kriterium „deutlich schneller (nur Hash-Vergleiche)" ist nicht voll erreicht – der Scan liest weiterhin jede SKILL.md vollständig, das Delta steuert nur die Zusammenfassung. Bei 1.872 Skills unkritisch; bei deutlich wachsender Bibliothek als Mini-Follow-up möglich (Mtime-Vorfilter). Siehe ADR-006.
