# MemPalace-Übersicht: Was liegt wo (Wing `freebuff_dev_setup`)

> Inhaltsverzeichnis des MemPalace-Palasts dieser Maschine. Kuratiert, nicht
> vollständig — Regelwerk und Ablage-Konventionen stehen in
> [docs/mempalace-regeln.md](mempalace-regeln.md), die Entscheidung zu dieser
> Selbstbeschreibung in [ADR-011](decisions/ADR-011-mempalace-uebersicht-navigation.md).
> Pflege-Regel: neue Drawer-**Kategorie** → hier ergänzen + Palast-Index-Drawer
> neu ablegen (ADR-011, Decision 2).

## Schnelleinstieg fuer Agenten (blinde Suche)

```bash
mempalace search "Palast-Index"          # dieser Einstieg (Navigations-Drawer)
mempalace search "ADR-010"               # Architektur-Entscheidungen
mempalace search "Mission COMPLETED NextDNS"   # Missions-Ergebnisse
pwsh -File memory-ingest/check-mempalace.ps1   # Diagnose (Exit 0/1/2)
```

Identity aller Ablagen: `maxhambi:freebuff:freebuff-dev-setup`
(host:harness:project). Wing: `freebuff_dev_setup`.

## Rooms und was dort liegt

| Room | Inhalt | Wie dort hin |
|------|--------|--------------|
| `problem` | Session-Transcripts (automatisch minedi) — hier landen die produktiven Gespraechs-Auszuege | Scheduled Task `MemoryIngest` (ADR-007), laeuft automatisch |
| `documentation` | Kuratierte Referenzen: ADR-Spiegel, NextDNS-API-Referenz, Navigations-Drawer „Palast-Index" | manuell via CLI/STDIO (ADR-008) |
| `milestone` | Missions-Plaene und -Abschluesse (z. B. NextDNS-Mission: Plan-Drawer + „Mission COMPLETED"-Drawer) | manuell bei Missionsende |
| weitere | thematische Rooms aus frueheren Minelaufen | `mempalace search` oder Mine-Log |

## Bekannte Drawer-Kategorien (Stand 2026-09-29)

- **Missions-Doku (milestone/documentation):** NextDNS-Mission — Plan
  (`..._milestone_e1fa73b3...`), Ergebnis „Mission COMPLETED"
  (`..._milestone_d2d29f57...`), API-Referenz
  (`..._documentation_3bc98341...`). Quelle der Wahrheit im Repo:
  `nextdns-manager/PLAN.md`.
- **Session-Transcripts (problem):** automatischer Ingest ueber
  `memory-ingest/` — nie manuell duplizieren; Live-Schutz (Staleness-Fenster)
  gilt, Details siehe ADR-007.
- **ADR-Spiegel (documentation):** Entscheidungen aus
  `docs/decisions/` werden bei grossem Aussenumfang als Drawer gesichert
  (z. B. ADR-010/011 ab 29.09.2026); die Repo-Datei bleibt die Quelle.
- **Palast-Index (documentation):** der Navigations-Drawer, der auf diese
  Datei verweist (ADR-011).

## Ablage-Regeln (Kurzform — verbindlich ist mempalace-regeln.md)

- durable Ergebnisse (Entscheidungen, Fakten) → Drawer; single-valued Fakten
  → KG (`kg_add`/`kg_supersede`/`kg_invalidate`).
- Consent/diagnose: Exit 2 = CLI/STDIO-Fallback aktiv (ADR-008) — kein
  Grund, den Ledger `~/.freebuff/mcp.json` anzufassen (ADR-010).
- Niemals Secrets ablegen; Quote verbatim, nie paraphrasieren.
