# Hook-Registrierung: Session-End

> Namenskonvention: Ordnerebene-Agent-Dateien heissen in allen Repos `AGENTS.md`
> (keine CLAUDE.md). Das Root-`CLAUDE.md` ist nur ein lokaler, gitignored Symlink
> auf `AGENTS.md`. Der Guardian prueft AGENTS.md als eigenes Ziel.

Der Hook meldet bei Session-Ende, welche Doku-Artefakte die Session veraendet hat.
Ziel: `session-docs-guardian` wird getriggert, bevor die Session schliesst.

## Claude Code / claude-flow (`~/.claude/settings.json`)

Im `"hooks"`-Objekt ergaenzen:

```json
"SessionEnd": [
  {
    "hooks": [
      {
        "type": "command",
        "command": "pwsh -NoProfile -File \"C:\\Users\\Max Hambi\\.agents\\skills\\session-docs-guardian\\hooks\\session-end.ps1\"",
        "timeout": 15000
      }
    ]
  }
]
```

Optional mit hartem Gate (Exit 1 bei Stale-Befund, falls die Umgebung das
unterstuetzt): Parameter `-Check` anhaengen.

## Stop-Hook-Variante (frueherer Trigger)

Wenn die Session nur `Stop` statt `SessionEnd` emittiert, denselben Command
unter `"Stop"` registrieren - der Skriptaufruf ist identisch.

## Cline / andere Hosts

Hosts ohne Session-End-Hook: den Skill manuell triggern. Die Description des
Skills enthaelt die Trigger-Woerter ("wrap up", "Sitzung beenden",
"Doku aktualisieren"), sodass der Agent beim Verabschieden anschlaegt.

## Validierung

```powershell
# Syntax
pwsh -NoProfile -Command "[void][ScriptBlock]::Create((Get-Content -Raw '<pfad>'))"

# DryRun im Repo
pwsh -NoProfile -File <pfad>\session-end.ps1
```

Erwartet: Report mit `OK` (nichts stale) oder `STALE`-Zeilen plus
Aktionsaufruf. Exit ist immer 0 (außer mit `-Check`).
