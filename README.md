# tools-entwicklung

Windows Scheduled Tasks & Watchdogs as code.

- `plan.md` – genehmigter Masterplan (Slices T1–T7), verbindlich für die Implementierungs-Sitzung
- `node-watchdog/` – globaler Node/Electron/esbuild-Watchdog (DryRun-Default, Whitelist, Baum-Kill)
- `task/` – exportierte Task-XMLs aller eigenen Scheduled Tasks

## Wiederherstellung eines Tasks (GUI)

1. Aufgabenplanung öffnen (`taskschd.msc`)
2. „Aufgabe importieren…"
3. XML aus `task/` wählen (enthält absolute Pfade dieses Rechners – ggf. Aktionspfad anpassen)

## Qualitätsgate

`npm run lint` (Biome) · `npm run syntaxcheck` (PS-Parser) · `npm test`
erzwungen durch `scripts/hooks/pre-push` (aktivieren: `git config core.hooksPath scripts/hooks`).
