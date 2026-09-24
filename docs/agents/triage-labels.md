# Triage Labels

Die fünf kanonischen Triage-Rollen und ihre Label-Strings in diesem Repo:

| Rolle | Label-String | Bedeutung |
|-------|--------------|-----------|
| needs-triage | `needs-triage` | Maintainer muss bewerten |
| needs-info | `needs-info` | Wartet auf Reporter |
| ready-for-agent | `ready-for-agent` | Vollständig spezifiziert, AFK-fähig |
| ready-for-human | `ready-for-human` | Braucht menschliche Umsetzung |
| wontfix | `wontfix` | Wird nicht umgesetzt |

Die Defaults entsprechen den Rollennamen. Existiert ein Label auf GitHub noch nicht, wird es bei Bedarf mit `gh label create` angelegt.
