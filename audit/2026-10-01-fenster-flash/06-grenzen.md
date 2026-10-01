# Grenzen des Audits

Transparenz statt Vortaeuschung: was dieses Audit-Paket leistet und was
nicht.

## Nicht exportierbar

1. **Interne Denknotizen.** Der Agent (Codebuff/Freebuff) arbeitet mit
   internen Reasoning-Notizen. Diese sind keine Datei-Artefakte und
   koennen nicht als Textdatei ausgegeben werden. Das Audit
   rekonstruiert stattdessen jede Entscheidung vollstaendig pruefbar:
   - `01-protokoll.md`: jeder ausgefuehrte Befehl + inhaltstreuer
     Ausgabeauszug + Zweck + Schluss
   - `03-entscheidungen.md`: jede Entscheidung mit Alternativen und
     Begruendung
   - `02-beweise/`: die geprueften Rohtexte selbst (XMLs, Log-Snapshot,
     Wrapper-Original), unabhaengig von jedem Agenten lesbar
2. **Gesamtes Sitzungsprotokoll.** Alle sichtbaren Nachrichten dieser
   Sitzung liegen im Freebuff-Client (Thread-Verlauf). Das Audit
   dupliziert sie nicht vollstaendig, sondern deckt die
   Untersuchungs- und Fix-Schritte ab.

## Gepruefte Aussageklassen

| Klasse | Wo nachpruefbar | Vertrauensbasis |
|---|---|---|
| Trigger-Intervall | `02-beweise/*.xml`, Pruefung 2 | Windows-eigene Exporte |
| Laufhistorie | Pruefung 3 | Watchdog-Log der Runtime |
| Mechanismus (conhost-Flash) | `01-protokoll.md` P6 | Dokumentiertes Windows-Verhalten, Reproduzierbar via VORHER-XML + Re-Import |
| Wrapper-Weiterreichung | Pruefung 1 + P8-Smoketest | Live-Aktion + apply=True-Beweis |
| Ausschluss anderer Ursachen | `01-protokoll.md` P3, P5 | Vollstaendige Task-Inventare, WMI-Abfrage |

## Was das Audit nicht beweist

- Dass zu jedem historischen Zeitpunkt genau der Watchdog geblitzt hat:
  dafuer war die TaskScheduler-Historie deaktiviert (P7). Der Beweis
  beruht auf Trigger + Log-Raster + Mechanismus, nicht auf Event-IDs.
- Zukunft: nach einem Windows-Update koennte sich das Verhalten von
  conhost/wscript aendern. Die Selbstpruefung (05/99) prueft den
  Ist-Zustand jederzeit nach.

## Historie (seit P11 aktiv)

Damit kuenftige Vorfuelle beweisbar sind. Aktiviert 2026-10-01 im
Rest-Migrations-Nachtrag (P11, Admin-Erhoehung Operator-approved);
erste Events fliessen seit 13:20. Nachkommando zur Verifikation:

```powershell
wevtutil get-log Microsoft-Windows-TaskScheduler/Operational   # enabled: true
```
