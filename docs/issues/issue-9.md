#9: Slice 8: Semantische Suche via routed (/)
<!-- mirror-sync: source=github:MaxHambi/freebuff-dev-setup#9 sha256:853959928a383ea5c52f22a7077ac0fe3ebd47dc8fdab2fbe74bfbbb52430982 synced=2026-09-30T05:24:16Z -->

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#9](https://github.com/MaxHambi/freebuff-dev-setup/issues/9).
> Label: `ready-for-agent` / `wontfix`. Status: **geschlossen (not planned, wontfix)** — TUI-Slice; Zukunft durch ADR-006 entschieden (OpenTUI-Eigenbau eingestellt, externe Tools skill-manager/SkillSpector).
> Closure-Kommentare: [#9 (Kommentar 1)](https://github.com/MaxHambi/freebuff-dev-setup/issues/9#issuecomment-5826071596)

> Detail-Spiegel mit Implementierungsnotizen: [skills-manager/docs/issues/slice-8-semantic-search.md](../../skills-manager/docs/issues/slice-8-semantic-search.md) (keine mirror-sync-Header, dokumentierte Abweichung). Raeumungs-Kandidat (C7, 2026-09-30).

## Original-Body

## Parent

#1

## What to build

Semantische Suche in der TUI: `/` öffnet eine Suchleiste (OpenTUI Input), die Eingabe wird an `routed route "<query>" --json` geschickt (über die installierte routed-CLI via PowerShell, Fehler werden abgefangen). Die zurückgegebenen Skill-Treffer werden im Baum hervorgehoben (z. B. Relevanz-Rang als Zahl), Nicht-Treffer ausgegraut; die Ansicht ist ein Overlay-Modus, der mit Esc verlassen wird und den normalen Baum unbeschädigt zurücklässt. Suche funktioniert gruppenübergreifend über alle Skills des Index.

Die Auswertung der routed-JSON-Antwort (Pfadematching gegen den Index, Ranking-Übernahme) ist als pure Funktion getestet; die TUI zeigt nur das Ergebnis. Ohne erreichbares routed bleibt die Suche lokal (Substring-Match über Name/Beschreibung), damit das Feature nicht komplett wegbricht.

## Acceptance criteria

- [ ] `/` öffnet Suchleiste, Eingabe löst routed-Anfrage aus, Treffer sind im Baum hervorgehoben mit Rang
- [ ] Esc verlässt den Suchmodus; Baum, Auswahl und Cursor sind im Originalzustand
- [ ] Die Auswertefunktion mappt routed-Treffer korrekt auf Index-Einträge (inkl. Pfad-Varianten) und übernimmt das Ranking
- [ ] Ohne erreichbare routed-CLI greift lokaler Substring-Fallback, es gibt keinen Absturz
- [ ] Lib-Tests für die JSON-Auswertung und den Fallback; Renderer-Test für Hervorhebung + Overlay

## Blocked by

- #3

## Kommentare

> **MaxHambi**: **Geschlossen als `wontfix` – siehe [ADR-006](https://github.com/MaxHambi/tools-entwicklung/blob/master/docs/decisions/ADR-006-externe-skill-manager-tools.md) (2026-09-25).**

Die TUI-Entwicklung des Skills-Managers ist eingestellt: Die Funktionalität dieses Slices wird abgedeckt durch

- **[skill-manager](https://github.com/abubakarsiddik31/skill-manager)** (Desktop-App, MIT) – einheitliche Sicht über elf Skills-Ordner inkl. `~/.agents/skills`, Browse/Install aus GitHub-Collections, Enable/Disable, Edit/Delete, Suche,
- **[SkillSpector](https://github.com/NVIDIA/SkillSpector)** (Scanner, Apache-2.0) – Security-Scan mit 71 Patterns und Risk-Score, statisch ohne LLM/API-Keys.

Verbleibender Scope des Skills-Managers: Analyse-CLI (Slice 1, PR #12) und optional die Mirror-Gruppierung (#6, Backlog). Die SkillSpector-Integration in die Analyse-CLI ist als eigenes ai-improvement-Issue angelegt.
