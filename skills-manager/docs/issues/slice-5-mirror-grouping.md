## Parent

#1

> **Backlog (ADR-006, 2026-09-25):** Offen, low priority - kein externes Aequivalent (thematische Gruppenkopie fuer den Datei-Explorer). Issue #6 bleibt offen; Bedarf entscheidet, ob gebaut wird.

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
