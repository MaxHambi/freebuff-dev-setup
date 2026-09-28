# #41: Slice 5: TUI-Menue + CLI-Parametermodus (run.ps1)

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#41](https://github.com/MaxHambi/freebuff-dev-setup/issues/41).
> Label: `ready-for-agent`. Status: **geschlossen (completed)** via PR #48, gemerged als `d79a918`.

## Parent

#36 (Umbrella)

## What to build

Einstiegsebene: `run.ps1` mit param()-CLI-Modus (-Action Get-Profile/Get-Settings/Get-Logs/Add-Denylist/... mit Parametern, Non-Interactive-faehig, Exit-Codes dokumentiert) und interaktivem Menue-Modus (Show-NextDnsMenu). Menue-Dispatch als reine Tabelle (Menu.ps1: Action-Name -> Funktion + Parameter-Prompt) - I/O getrennt von Logik, testbar. Behebt Befund 8/9.

## Acceptance Criteria

- [ ] `run.ps1 -Action Get-Profile` laeuft non-interaktiv durch (Exit 0 bei Erfolg, 1 bei API-Fehler, 2 bei Config-Fehler)
- [ ] Alle Menue-Actions sind in einer Dispatch-Tabelle deklariert (kein switch-Case mit inline I/O)
- [ ] Menue-Modus faellt in Non-Interactive-Hosts auf Exit statt Endlosschleife
- [ ] `run.ps1` ohne -Action startet das Menue
- [ ] Beide Modi nutzen dieselben Modul-Funktionen (kein Duplikat-Code)

## Blocked by

#38 (Core; #39/#40 ergaenzen weitere Actions, Blockade fuer #42)
