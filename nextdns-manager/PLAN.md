# PLAN.md - NextDNS-Manager: Onboarding, Refactor, Verification

> **Source of Truth** fuer die Mission "NextDNS-Manager ins Repo aufnehmen,
> ueberarbeiten, refactoren & issue-ueberwacht ausfuehren".
> Genehmigt am 2026-09-28. Aenderungen am Plan werden hier nachgezogen
> (Repo = Quell der Wahrheit, GitHub-Issues sind der Tracker).

## 1. Ziel

Das Desktop-Script `C:\Users\Max Hambi\Desktop\nextdns-manager.ps1` (≈970
Zeilen, Monolith) wird als neues Projektverzeichnis `nextdns-manager/` ins
Repo uebernommen, nach Fehlern/Logikfehlern durchsucht, in saubere Module
zerlegt (Skill `code-refactoring-refactor-clean`), um sinnvolle Erweiterungen
ergaenzt und mit Test-/Lint-Gate abgesichert. Die Arbeit laeuft
**issue-first** (neue Issues #33–#40), mit Conventional Commits, Mirror
unter `docs/issues/` und finaler End-to-End-Pruefung gegen die Live-API.

## 2. Vorab-Einmalaktion (erledigt in dieser Mission)

**API-Doku in MemPalace einpflegen** (Duplikat-Check erledigt:
`mempalace search "NextDNS"` / `"api.nextdns.io"` → 0 relevante Treffer):

- Quelle als Markdown-Datei ablegen: `nextdns-manager/docs/nextdns-api.md`
  (kompletter Doku-Text von https://nextdns.github.io/api/) → Repo-Quelle
  der Wahrheit und Mining-Quelle
- Drawer filen: room `documentation`,
  `added_by=maxhambi:freebuff:freebuff-dev-setup`, Content = Endpoint-Liste +
  Error-Modell (400 vs. `200 OK + errors[]`) + Limits (Logs 10–1000,
  Analytics 1–500) + Time-Series/Streaming-Verweise + **Quellenpfad**
  `nextdns-manager/docs/nextdns-api.md`
- Keine Secrets im Drawer; danach `mempalace search` als Smoke-Verify

## 3. Befunde (Script-Analyse, API-Doku-belegt)

> **Status nach Umsetzung (2026-09-28):** Alle 10 Befunde sind in den
> Slices #37-#42 behoben und durch Pester (30 Tests) + Dauer-Smokes (28
> Checks) abgesichert. Details je Slice in den Issue-Kommentaren.

| #  | Schwere | Befund | Status |
|----|---------|--------|--------|
| 1  | **Hoch** | Logikfehler: User-Fehler der API (`200 OK + { errors: [...] }`, z. B. ungueltige Domain in Denylist) werden als Erfolg gewertet — `errors` wird nie geprueft | ✅ behoben (#38/#40) |
| 2  | **Hoch** | API-Mythos im Kopf-Kommentar: 400 „extraneous" kam von einem (inzwischen korrekt entfernten) `type=`-Parameter auf `reasons` — der Kommentar behauptet faelschlich `reasons` akzeptiere generell keinen `type`-Parameter; den gibt es schlicht nicht auf dieser Dimension. Kommentar korrigieren | ✅ behoben (#39, NoTypeDims-Registry) |
| 3  | **Hoch** | Kein Rate-Limit-Handling: `429` wird nicht speziell behandelt (`Retry-After`-Header respektieren statt fix 1 s) | ✅ behoben (#38) |
| 4  | Mittel | `Get-NextDnsAllLogs` sendet `limit=1000` ohne Clamp (Doku: ≥10, ≤1000) und hat **keine Dedupe** — Cursor-Wiederholung kann Eintraege doppelt liefern | ✅ behoben (#38) |
| 5  | Mittel | `Invoke-NextDnsApi`/`-Raw` sind ~80 % Duplikate; `UseBasicParsing` ist in PS 7 obsolet | ✅ behoben (#38, einheitliche API-Schicht) |
| 6  | Mittel | Write-Pfad (POST denylist) bewertet *jede* nicht-leere Antwort als OK; ein `errors`-Objekt in `data` bleibt unbemerkt (→ Befund 1) | ✅ behoben (#40) |
| 7  | Mittel | Monolith: Konfig, Auth, HTTP, Report, Menue in einer Datei; Report-Funktion ~180 Zeilen (Skill-Checkliste: >50 = split) | ✅ behoben (#37-#41, 11 Submodule) |
| 8  | Mittel | Keine Tests, kein Lint; `$DebugMode`-Ausgaben ungepuffert; Menue-Dispatch enthaelt I/O gemischt mit Logik (nicht testbar) | ✅ behoben (#41/#42: Dispatch-Tabelle + 4 Gate-Schichten) |
| 9  | Niedrig | `exit 1` ohne dokumentierte Exit-Codes; `Clear-Host`/`ReadKey`-Fallbacks ok, aber Menue-Texte hart verdrahtet | ✅ behoben (#41: Exit-Codes 0/1/2, Non-Interactive-Exit) |
| 10 | Niedrig | Helper (`ConvertTo-JsonSafe`, `Get-AbsolutePath` u. a.) global im Script-Scope statt Modul-Funktionen | ✅ behoben (#37/#42: Modul-Scope + explizite Export-Liste) |

## 4. Zielarchitektur `nextdns-manager/`

```
nextdns-manager/
├── NextDnsManager.psd1            # Root-Modul (Manifest, exportierte Funktionen)
├── NextDnsManager.psm1            # dot-sourced Submodule
├── src/
│   ├── Config.ps1                 # $script:Config (BaseUrl, Limits, Dimensions-Regime), [pscustomobject]-typisiert
│   ├── Auth.ps1                   # SecretManagement-Load + Validierung, -Credential-Injektion fuer Tests
│   ├── Api.ps1                    # Invoke-NextDnsApi (einheitlich, Retry+429/Retry-After, Error-Parsing)
│   ├── ErrorHandling.ps1          # Resolve-NextDnsError: 400+errors[], 200+errors[], HTTP-Status
│   ├── Pagination.ps1             # Get-NextDnsNextPage (generisch), Clamp-Helfer, Dedupe
│   ├── Read.ps1                   # Get-*Profile/Settings/Blocklists/Denylist/Allowlist/Logs/Analytics
│   ├── Analytics.ps1              # Dimensions-Registry (reasons: kein type; destinations: type-Pflicht), +domains/ips, ;series-Option
│   ├── Write.ps1                  # Add-/Remove-Denylist/Allowlist, Settings-PATCH, supports -WhatIf/-Confirm
│   ├── Report.ps1                 # Export-FullReport (zerlegt: Report-Header/Sections/Summary), JSON/CSV-Exporte
│   └── Menu.ps1                   # TUI-Menue (reine Dispatch-Tabelle → testbar)
├── tests/
│   ├── NextDnsManager.Tests.ps1   # Pester 5: Error-Parsing, Pagination-Dedupe, Clamp, Dispatch
│   └── fixtures/                  # statische JSON-Antworten (200+errors, 400, 429, cursor)
├── docs/
│   ├── nextdns-api.md             # API-Doku (Repo-Quelle + MemPalace-Mining-Quelle)
│   └── README.md                  # Setup, Menue/CLI-Modus, Architektur, Verify-Integration
├── setup.ps1                      # Onboarding: Modul-Prereqs, Vault-Registration, Set-Secret-Aufforderung
└── run.ps1                        # Einstieg: param()-CLI-Modus ODER interaktives Menue
```

### Module-Entscheidungen (alle Kandidaten bewertet)

| Modul | Entscheidung | Warum |
|---|---|---|
| **PSScriptAnalyzer** | ✅ **Ja** — in `scripts/test.ps1` + `verify` integriert, repo-eigene Settings (`PSScriptAnalyzerSettings.psd1`) | Statisches Lint fuer alle Repo-PS1, passend zum vorhandenen Gate-Stil |
| **Pester 5** | ✅ **Ja** — Unit-Tests gegen gemockte `Invoke-RestMethod` (Seam in `Api.ps1`), keine Live-Calls | Repo hat bisher nur Watchdog-Smoke; Skill-Checkliste verlangt Tests |
| **SecretManagement + SecretStore** | ✅ bleibt | Schon im Einsatz, bewaehrt |
| **PSFramework** | ❌ | Overkill: eigenes Config-/Logging-Oekosystem konterkariert die schlanke Modulstruktur |
| **InvokeBuild** | ❌ | Repo nutzt npm-Skripte als Task-Runner (`verify`); ein zweites Build-System waere Drift |
| **PSMenu / Spectre.Console / PSWriteColor** | ❌ | Menue ist ~60 Zeilen; externe TUI-Abhaengigkeit lohnt nicht |
| **Terminal-Icons / ConsoleGuiTools** | ❌ | rein kosmetisch bzw. Out-GridView-Ersatz ohne Mehrwert |
| **RestMethods / PSRest** | ❌ | `Invoke-RestMethod` mit Retry-/Error-Wrapper deckt alles ab; errors[]/cursor-Logik bauen wir ohnehin selbst |

### Funktionale Erweiterungen (API-Doku-belegt)

- Analytics-Dimensionen `domains` (mit `status`/`root`-Parametern) und `ips` ergaenzen
- Logs: `--status`, `--search`, `--device`, `--from/--to`, `--raw`, `--sort` Parameter
- Logs: `DELETE /logs` (Verlauf loeschen) mit `-Confirm`
- Profile: Liste aller Profile + Profil-Wechsel (aktuell nur hart kodiertes `$ProfileId`)
- Settings-PATCH (Beispiel: `blockPage.enabled`, `performance.cacheBoost`) mit Dry-Run
- Time-Series (`;series`) optional per Flag
- Report-Export mit optionalem `without-logs`-Modus (schneller Report)

## 5. Issues & Commit-Sequenz (git-ueberwacht)

Neue GitHub-Issues (naechste freie Nummern, beim Anlegen verifizieren),
jeweils mit Mirror `docs/issues/issue-NN.md` (nach #32-Muster) im selben PR,
Index in `docs/issues/README.md` ergaenzt:

| Issue | Typ | Inhalt | Commits (Conventional, `Refs #n` im Body) |
|---|---|---|---|
| **#33** | Umbrella/PRD | NextDNS-Manager: Onboarding + Refactor + Verification (User Stories nummeriert, Out of Scope) | — (nur Issue) |
| **#34** | Slice | Onboarding: Ordner `nextdns-manager/`, Root-Modul/Manifest, `setup.ps1`, API-Doku-Datei + MemPalace-Drawer | c1 `feat: nextdns-manager als Modul-Projekt onboarding`, c2 `feat: Setup-Assistent fuer Vault-Secrets und Modul-Prereqs` |
| **#35** | Slice (blocked by #34) | Core: `Config.ps1`, `Auth.ps1`, `Api.ps1` (Retry+429/Retry-After), `ErrorHandling.ps1` (200+errors[]-Fix), `Pagination.ps1` (Dedupe, Clamp) | c3 `feat: NextDns.Api-Modul mit Retry, Rate-Limit und Fehlerbehandlung`, c4 `feat: NextDns.Auth via SecretManagement mit testbarem Seam`, c5 `fix: Pagination-Dedupe und limit-Clamps (Logs 10-1000, Analytics 1-500)` |
| **#36** | Slice (blocked by #35) | Read-Funktionen + Analytics-Regime-Korrektur (Befund 2), neue Dimensionen `domains`/`ips`, Logs-Filter | c6 `feat: Read-Funktionen inkl. neuer Analytics-Dimensionen domains/ips`, c7 `fix: reasons-Dimension korrekt ohne type-Parameter dokumentiert` |
| **#37** | Slice (blocked by #36) | Write-Funktionen mit Safety (`-WhatIf`/`-Confirm`), Settings-PATCH, Logs-Clear | c8 `feat: Write-Funktionen mit WhatIf/Confirm-Schutz` |
| **#38** | Slice (blocked by #35) | TUI-Menue + CLI-Modus (`run.ps1 -Action Get-Profile`, Non-Interactive-faehig), Dispatch-Tabelle | c9 `feat: TUI-Menue und CLI-Parametermodus` |
| **#39** | Slice (blocked by #34–#38) | Tests (Pester 5, gemockte API) + **PSScriptAnalyzer in `scripts/test.ps1`/`verify`** + Syntaxcheck automatisch ueber neue .ps1 | c10 `test: Pester-Suite fuer Error-Parsing, Pagination, Dispatch (gemockt)`, c11 `chore: PSScriptAnalyzer in Verify-Gate integriert` |
| **#40** | Slice (blocked by #34–#39) | Doku: README (Setup, Architektur, CLI), Verify-Gate-Doku-Aktualisierung, Final-Smoke-Protokoll | c12 `docs: nextdns-manager README und Verify-Integration dokumentiert` |

### Prozessregeln (Issue-/Worktree-Fibel)

- Issues in Abhaengigkeitsreihenfolge anlegen (Umbrella zuerst → echte
  Nummern in "Blocked by")
- Label-Flow: `needs-triage` → direkt `ready-for-agent` (Maintainer-PRD)
- Ein Branch+PR pro Issue (kleine Slices im Haupt-Checkout, kein Worktree
  noetig — keine parallele Sitzung, kein lang laufender Prozess)
- `Closes #n` **nur** im PR-Body, `Refs #n` im Commit-Body
- Pre-Push-Gate (`npm run verify`) muss je PR gruen sein

## 6. Verifikation ("100 % Funktionalitaet")

1. **Statisch:** `npm run verify` gruen (inkl. neuer PSScriptAnalyzer- und
   Pester-Schritte, Syntaxcheck greift automatisch auf neue .ps1)
2. **Unit (Pester, gemockt):** Error-Parsing (400, 200+errors[],
   429+Retry-After), Pagination-Dedupe, Limit-Clamps, Dimensions-Registry
   (reasons ohne type, destinations mit type), Dispatch-Tabelle,
   Config-Validierung
3. **Live-Smoke (mit Operator, echte Credentials):**

   > **Durchgefuehrt 2026-09-28 (AFK-Modus, Read-only-Anteile):**
   > Test-Connection (Profil „FireTV" via Vault), Get-Profile,
   > Get-Settings, Get-Denylist (**374 Eintraege** inkl. FireTV-OTA-
   > Domains), Get-Logs (leere Datenmenge - plausibel: Logs deaktiviert
   > oder kaum Traffic), Get-Analytics status, Export-Report ohne Logs
   > (Errors=0). **Schreibende Teile (Denylist-Roundtrip, Clear-Logs)
   > NICHT ausgefuehrt** - kein Operator-Consent im AFK-Modus; nachholbar.
   >
   > **Live-Findings (sofort behoben):** (1) Denylist-Endpoint akzeptiert
   > KEINEN limit-Parameter (400 extraneous) - nicht paginiert, embedded
   > Array; Get-NextDnsDenylist/Allowlist nutzen kein AllPages mehr.
   > (2) Splatting von $null an parameterlose Funktionen (CLI-Fix).
   > (3) JSON-Parameter-Variante -ActionParameterJson fuer Cross-Shell-CLI
   > inkl. Reihenfolge-Fix (Merge VOR dem Mandatory-Check).

   - [x] `Test-Connection` (Profil-Liste + eigenes Profil)
   - [ ] Denylist-Write-Roundtrip (Test-Domain add/verify/remove) - wartet
         auf Operator-Consent
   - [x] Full-Report ohne Logs → Datei geprueft (Errors=0)
   - [x] Logs-Pagination klein (Limit 30)

   Historische Planung (Original):

   - `Test-Connection` (Profile-Liste + eigenes Profil)
   - Menue-Items 1–5, 7, 8 je einmal (Read-Pfad)
   - Denylist: Test-Domain hinzufuegen → verifizieren → entfernen
     (Write-Roundtrip inkl. `errors[]`-Pfad bei ungueltiger Domain)
   - Full-Report (mit und ohne Logs, `MaxPages=2`) → Datei pruefen
   - Logs-Pagination klein (Limit 30, eine Folgeseite)
4. **Issue-Closure:** je Issue ACs einzeln abhaken, Reste als
   Issue-Kommentar

## 7. Out of Scope (bewusst nicht in diesem Durchlauf)

- Streaming-Watcher (`/logs/stream`, SSE) → eigener Folge-Issue, wenn gewuenscht
- Scheduled Task fuer automatische Reports
- Umbau der Skills-Manager-/Watchdog-Module — nextdns-manager bleibt
  eigenstaendiger Ordner

## 8. Abschluss

- MemPalace: Ergebnis-Drawer (milestone/decision) nach #40-Closure mit
  Quellenpfad
- `blueprint/context/current-feature.md` bleibt unberuehrt (Repo-Workflow
  nutzt hier Issue-/PR-Pfad, kein `/feature`-Spec)
- Alle 8 Issues via PR geschlossen, Mirror-Index vollstaendig
