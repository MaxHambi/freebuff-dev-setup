# #64: GitHub-Raeumung - Issues schliessen/loeschen + ROADMAP (Slice 8 Struktur-Plan)
<!-- mirror-sync: source=github:MaxHambi/freebuff-dev-setup#64 sha256:8358cc9465f3d525feaf27f76ead9214b12c71811f73d4069590f2029f7bdb8a synced=2026-09-29T15:19:44Z -->

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#64](https://github.com/MaxHambi/freebuff-dev-setup/issues/64).
> Label: `ready-for-agent`. Status: in Arbeit (Slice 8 des Struktur-Plans
> `docs/plan-2026-09-29-struktur-ordnung.md`).

## Erledigt (dieser Slice)

**ADR-Status finalisiert:** alle 12 ADRs Accepted; ADR-009-Statuszeile verweist jetzt explizit auf die Teil-Supersession durch ADR-010 (Rueckverlinkung ergaenzt); ADR-001-Statuszeile in docs/index.md korrigiert.

**Issues geschlossen (mit Abschlusskommentar):**
- #16 (Watchdog-Reviewer-Entscheidungen) — alle 3 Punkte entschieden (Defaults bestaetigt, Whitelist bereinigt, ADR-001 Accepted), bewiesen durch ADR-001-RCA + Runtime-Log.
- #6 (TUI-Slice Mirror-Gruppierung) — obsolet durch ADR-006 (TUI-Eigenbau verworfen).
- #20 (gm-Evaluierung) — Vorarbeit abgeschlossen (#61/ADR-012); Entscheidung faellt im Betrieb.

**ROADMAP erstellt:** `docs/ROADMAP.md` — Reihenfolge nach Abhaengigkeiten: #15 (Index-Divergenz) → #19 (SkillSpector) → #17 (Skills-Sync) → gm-Nachfolge → Session-Hook-Entscheid → Nach-Merge-Lauf (#63/#62 schliessen, Loesch-Kandidaten mirror-first loeschen). README + docs/index.md verlinken die Roadmap.

## Loesch-Kandidaten (Operator-Bestaetigung steht aus — MIRROR-FIRST ist erfuellt)

Kriterium: Inhalt vollstaendig im Mirror `docs/issues/` gesichert UND Arbeit voll in master gemergt.

| Kandidaten | Grund |
|---|---|
| #21, #22, #23, #24, #25, #26 (Umbenennung) | geschlossen via PR #27 (in master), Mirrors vorhanden |
| #36 - #43 (nextdns-manager Slices) | geschlossen via PR #44 - #51 (in master), Mirrors vorhanden |

**Nicht geloescht werden:** #28-#32, #53, #54, #56 (Arbeit faehrt ueber PR #59 in master ein — Loeschung erst nach dessen Merge), #61/#62/#63/#64 (aktuell), #14/#15/#17/#19 (Roadmap-Posten).
