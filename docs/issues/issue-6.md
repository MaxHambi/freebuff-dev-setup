#6: Slice 5: Mirror-Gruppierung - Buckets, routed-Fallback, Dry-Run
<!-- mirror-sync: source=github:MaxHambi/freebuff-dev-setup#6 sha256:gone synced=2026-09-30T06:03:32Z -->

> Spiegel des GitHub-Issues [MaxHambi/freebuff-dev-setup#6](https://github.com/MaxHambi/freebuff-dev-setup/issues/6).
> Label: `ready-for-agent`. Status: **geschlossen (completed)** — Mirror-Gruppierung als Backlog-Thematik der Analyse-CLI weitergeführt (ADR-006-Kontext).
> Closure-Kommentare: [#6 (Kommentar 1)](https://github.com/MaxHambi/freebuff-dev-setup/issues/6#issuecomment-5826076757), [#6 (Kommentar 2)](https://github.com/MaxHambi/freebuff-dev-setup/issues/6#issuecomment-5893113161)

> Detail-Spiegel mit Implementierungsnotizen: [skills-manager/docs/issues/slice-5-mirror-grouping.md](../../skills-manager/docs/issues/slice-5-mirror-grouping.md) (keine mirror-sync-Header, dokumentierte Abweichung). Raeumungs-Kandidat (C7, 2026-09-30).

## Original-Body

## Parent

#1

## What to build

Baut den thematischen Gruppen-Mirror: Ein CLI-Lauf (`--dry-run` zuerst) ordnet jeden Skill über Keyword-Buckets in fester Priorität einer Gruppe zu (KI-Agents, Cloud/DevOps, Backend/API, Web-Frontend, Game/3D, Automation/SaaS, Content/SEO, Security, Testing, Data/ML, Datenbank, Mobile, Business, Docs/Wiki, Meta-Skills, Health, Personas, Sonstige – erster Treffer gewinnt) und kopiert die kompletten Skill-Ordner nach `~/.agents/skills-org/<gruppe>/<skill>/`.

- **Routed-Fallback**: Skills ohne Bucket-Treffer (oder mehrdeutige) werden per `routed route "<name + beschreibung>" --json` semantisch einer Gruppe zugeordnet; schlägt das fehl (oder routed nicht installiert) → Gruppe `other`. Der Aufruf läuft über die installierte routed-CLI via PowerShell; Fehler werden abgefangen, der Mirror-Bau funktioniert auch ohne routed.
- **Container-Ordner** (Repo-Doku, unvollständige Ordner, Container wie LibreOffice/Security-Suiten/Sendblue) bleiben als eigene Gruppen erhalten, es geht nichts verloren.
- Die originale Bibliothek und ihr Installations-Manifest werden nie verändert.
- **Dry-Run**: Report mit Zuordnung pro Gruppe (Anzahl, Liste), bevor kopiert wird; erst `--apply` kopiert.
- Ein Copy-Manifest protokolliert jede Kopie (Quelle, Ziel, Gruppe) für spätere inkrementelle Sync-Läufe (Slice 7).
- Die Zuordnung wird gecacht (in der State-Datei), damit spätere Sync-Läufe neue Skills ohne Voll-Lauf einordnen können.

## Acceptance criteria

- [ ] `bun run src/group.ts --dry-run` erzeugt einen Zuordnungs-Report ohne zu kopieren
- [ ] `--apply` erzeugt `~/.agents/skills-org/<gruppe>/<skill>/` mit vollständigen Skill-Ordnern (ca. 89 MB Gesamtkopie)
- [ ] Bucket-Regeln: ein Skill mit "aws" im Namen landet in cloud-devops, einer mit "seo" in content-seo (geprüft per Fixtures)
- [ ] Ohne erreichbare routed-CLI landen Bucket-lose Skills in `other` und der Lauf schlägt nicht fehl
- [ ] Container-Ordner erscheinen als eigene Gruppen im Mirror
- [ ] Die Original-Bibliothek ist nach dem Lauf byte-identisch (geprüft über Manifest-Zählung, keine Schreiboperation)
- [ ] Copy-Manifest enthält Quelle, Ziel und Gruppe jeder Kopie
- [ ] Lib-Tests: Bucket-Zuordnung (Prioritäts-Reihenfolge), Fallback-Pfad, Dry-Run ohne Schreibeffekt

## Blocked by

- #2

## Kommentare

> **MaxHambi**: **Backlog (ADR-006, 2026-09-25):** Bleibt als einziger Baustein ohne externes Äquivalent offen – thematische Gruppenkopie der Bibliothek für den Datei-Explorer (Dry-Run zuerst, ADR-005 gilt weiter). **Low priority:** Ob gebaut wird, entscheidet der Bedarf beim manuellen Sichten der Skills. Kein aktiver Umsetzungsplan.

> **MaxHambi**: ## Abschluss (Slice 8, Struktur-Plan) — obsolet durch ADR-006

Der TUI-Eigenbau ist mit ADR-006 verworfen worden (skill-manager + SkillSpector uebernehmen Baum/Mirror-Funktionen). Dieser Slice-5-Issue „Mirror-Gruppierung (Buckets, routed-Fallback, Dry-Run)" gehoerte zu diesem verworfenen Eigenbau und wird nicht mehr umgesetzt.

Die Analyse-CLI (Scan/Klassifizierung/Delta-Index) bleibt das Kernstueck des skills-manager; die Gruppierungs-Funktion wuerde — falls jemals wieder gewuenscht — beim externen skill-manager angesiedelt werden, nicht hier. Siehe #19 (SkillSpector) fuer den angestrebten naechsten Schritt.
