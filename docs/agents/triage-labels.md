# Triage Labels

Die sechs kanonischen Triage-Rollen und ihre Label-Strings in diesem Repo:

| Rolle | Label-String | Bedeutung |
|-------|--------------|-----------|
| needs-triage | `needs-triage` | Maintainer muss bewerten |
| needs-info | `needs-info` | Wartet auf Reporter |
| ready-for-agent | `ready-for-agent` | Vollständig spezifiziert, AFK-fähig |
| ready-for-human | `ready-for-human` | Braucht menschliche Umsetzung |
| in-review | `in-review` | Änderungen im PR-Review |
| wontfix | `wontfix` | Wird nicht umgesetzt |

Die Defaults entsprechen den Rollennamen. Existiert ein Label auf GitHub noch nicht, wird es bei Bedarf mit `gh label create` angelegt.

## Board-Spiegel

Der Workflow `.github/workflows/project-mirror.yml` spiegelt diese Zustände
automatisch in den Board-Status des Dashboards (Backlog/Ready/In review/Done):
neue Issues landen auf Backlog, `ready-for-*` -> Ready, `in-review` ->
In review, Schließen -> Done. Voraussetzung ist das Repo-Secret
`PROJECTS_PAT` (Classic PAT mit `repo` + `project`), weil der Default-
Workflow-Token keine ProjectV2-Mutationen aus der Web-UI heraus darf.
