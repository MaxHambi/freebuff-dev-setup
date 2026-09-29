# ADR-010: Freebuff-MCP-Konfiguration — globaler Pfad `~/.agents/mcp.json` und Attestierungs-Ledger `~/.freebuff/mcp.json`

## Status

Accepted — supersede teilweise die Consent-Fluss-Beschreibung aus ADR-009
(Punkt 3 der Decision); ADR-008 (CLI-/STDIO-Fallback) bleibt unverändert
sanktioniert.

## Date

2026-09-29

## Context

Issue #28 ging von einem Consent-Prompt fuer die Projekt-`.mcp.json` aus. Der
Operator fand am 29.09.2026: Die Freebuff-UI hat **keine** Projekt-Ebene fuer
MCP — nur allgemeine API-/Connector-Einstellungen mit Add-Button. Die dort
gelisteten Server („Connections are shared across your agents") entsprechen
nicht der Projekt-Datei.

Beweiskette (alles am 29.09.2026 verifiziert, read-only):

1. **configKey-Mapping:** Der Approval-State enthaelt 5 Eintraege mit
   `configKey` = supabase (disabled), rayrun, synapse, routed, claimidx —
   exakt die Serverliste aus `~/.agents/mcp.json`. mempalace (nur in der
   Projekt-`.mcp.json`) fehlt.
2. **Mtime-Koppelung:** Beide Dateien wurden am 24.09.2026 01:55:09
   innerhalb von 4 ms geschrieben (`.agents` um .532, `.freebuff` um .536)
   — ein einziger synchroner Import-Vorgang. Seitdem wurde keine der
   Dateien von Freebuff angefasst, trotz wochenlangen Restarts mit
   vorhandener Projekt-`.mcp.json`.
3. **UI-Experiment:** Der Add-Button schrieb den mempalace-Block
   (`C:/Users/Max Hambi/.local/bin/mempalace-mcp.exe`, args=[]) in
   `~/.agents/mcp.json` (sha256 `1902aeee...` → `b43adf56...`), der
   Ledger blieb byte-identisch (`78dfe8eb...`).

Anatomie des Ledgers `~/.freebuff/mcp.json` (2091 Zeilen): pro Server ein
Hash-Key-Eintrag mit `configKey, enabled, launchHash, manifestHash,
generation, allowedTools, approvedManifest, credentialBindings`; die
`approvedManifest`-Blobs liegen inline (bis ~42 KB, daher die Groesse),
daneben drei `.bak`-Backups vom Importtag.

Rolle des Ledgers: Trennung von Deklaration und Attestierung. Die
Konfigurationsdatei kann jeder editieren — die Enforcement-Entscheidung
(„diese Freebuff-Installation hat genau diese Konfiguration mit genau
diesem Tool-Katalog freigegeben") lebt app-intern. `launchHash` bindet die
Freigabe an die exakte Server-Konfiguration (Aenderung = Neu-Freigabe),
`approvedManifest` konserviert den freigegebenen Tool-Katalog. Deshalb
erzwingt Loeschen des Ledgers nur eine Neu-Freigabe aller Server beim
naechsten Start — kein Datenverlust, aber kein Wartungsweg.

## Decision

1. **Kanonischer MCP-Deklarationspfad fuer Freebuff ist auf dieser Maschine
   `~/.agents/mcp.json`** (global). mempalace ist dort mit einem Eintrag
   (maschinenspezifischer Pfad) registriert.
2. **`~/.freebuff/mcp.json` ist der Attestierungs-Ledger:** nie manuell
   editieren, nie committen; Loeschen nur als bewusster Consent-Reset
   (Freebuff legt ihn beim naechsten Start neu an; `.bak`-Backups
   existieren).
3. **Die Projekt-`.mcp.json` bleibt lokal/gitignored als Dokumentation und
   Fallback fuer andere Harnesses** — die ADR-009-Decision bleibt gueltig,
   nur die Rolle wird praezisiert (Freebuff scannt sie nicht).
4. **Korrigierter Consent-Fluss** (ersetzt den Muster-Absatz aus ADR-009
   Punkt 3): Server ueber die Freebuff-UI hinzufuegen (schreibt
   `~/.agents/mcp.json`) → Freebuff neu starten → Freigabe des Tool-Katalogs
   erteilen → Ledger-Eintrag entsteht. Fuer neue Maschinen gilt derselbe
   Weg.
5. **ADR-008 bleibt:** CLI-/STDIO-Fallback und Diagnose-Gate sind der
   sanktionierte Weg, solange kein Ledger-Eintrag existiert.

## Alternatives Considered

### mempalace nur projekt-lokal lassen und auf UI-Support warten
- Pros: kleiner Scope, ADR-009-Idee konsistent
- Cons: nachweislich wirkungslos (UI scannt die Datei nicht), kein Zeitplan
- Rejected: blockiert #28/#29/#31 unbegrenzt

### Ledger per Hand editieren (Option D)
- Pros: sofortiger State-Eintrag
- Cons: launchHash-Ableitung unbekannt, app-internes Format,
  Korruptionsrisiko gegen den Enforcement-Zweck
- Rejected

### Alles auf CLI/STDIO re-scopen (ADR-008 als Hauptweg)
- Pros: kein UI-/Restart-Bedarf
- Cons: native MCP-Integration (allowedTools, Consent-Audit) bleibt ungenutzt
- Rejected als Hauptweg, bleibt als Fallback (Decision 5)

## Consequences

- Nach Restart + Freigabe stehen die `mempalace_*`-Tools nativ bereit
  (#29, #31 werden unblockt); bis dahin gilt Exit 2 (GELB) in der Diagnose.
- mempalace erscheint global in allen Projekten dieser Maschine — akzeptiert,
  da der Palast ohnehin maschinenweit ist (Wing `freebuff_dev_setup`).
- Der WARN-Text in `memory-ingest/check-mempalace.ps1` muss auf den
  korrigierten Fluss umgestellt werden (Slice 3 des Plans 2026-09-29).
- Neuer Consent-Bedarf bei jeder Aenderung am mempalace-Eintrag (Pfad, args)
  — bewusst, gleiche Semantik wie zuvor.

## Related

- Issue #28 (Consent-Freischaltung), Issue #29 (Tool-Verifikation)
- ADR-008 (CLI-/STDIO-Fallback, Diagnose-Gate)
- ADR-009 (Projekt-`.mcp.json` bleibt lokal — teilweise supersedet im
  Consent-Fluss)
- `docs/plan-2026-09-29-ready-for-human.md` (Slice 1-3)
