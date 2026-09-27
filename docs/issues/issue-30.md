# #30: mempalace.yaml: Room-Mapping memory_ingest ergaenzen (Edit-Tool-Blockade)

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#30](https://github.com/MaxHambi/freebuff-dev-setup/issues/30).
> Label: `ready-for-human`. Status offen.

## Ausgangslage (verifizierte Fakten)

- `mempalace.yaml` im Repo-Root steuert die Room-Zuordnung beim Mining (Verzeichnis -> Room + Keywords).
- Der neue Ordner `memory-ingest/` fehlt dort; der naechste Repo-Mine-Lauf wuerde ihn nach `general` einordnen (bestaetigt: Re-Mine 26.09.2026 hat die memory-ingest-Dateien nach `general` gefilmt).
- Edit-Tool-Blockade: Read- und Write-Tools melden [BLOCKED]/[FILE_READ_ERROR] fuer genau diese Datei (agentenseitig nicht editierbar; per-Bash-Delegierung wurde bewusst nicht als Workaround genutzt).

## Warum menschliche Umsetzung

Die Datei ist fuer Agent-Edit-Tools blockiert; der Eintrag ist eine
Zeilen-Ergaenzung im YAML-Block der Rooms-Liste.

## Checkliste

- [ ] In `mempalace.yaml` neben node_watchdog ergaenzen:
      `- name: memory_ingest` / `  description: Files from memory-ingest/` / `  keywords: [memory_ingest, memory-ingest]`
- [ ] Danach Verifizierung: `mempalace mine D:/freebuff-dev-setup` ordnet `memory-ingest/*` in den Room `memory_ingest` ein (kein `general` mehr)
