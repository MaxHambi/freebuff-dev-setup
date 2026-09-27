#Requires -Version 5.1
# ingest.ps1 - Orchestrierung des Memory-Ingest.
#
# Pipeline: bun run export (inkrementell, read-only DB) -> mempalace mine
# (--mode convos, idempotent) -> optionaler Such-Selbsttest. Abbruch bei
# Fehlern ($ErrorActionPreference = 'Stop' + je-Schritt-Checks). Laeuft
# manuell oder als Scheduled Task 'MemoryIngest' (Logging via Transcript).
#
# Benutzung:
#   pwsh -File ingest.ps1                 # export + mine (+ verify optional)
#   pwsh -File ingest.ps1 -DryRun         # nur Export-Plan zeigen
#   pwsh -File ingest.ps1 -SkipMine       # nur Transcripte exportieren
#   pwsh -File ingest.ps1 -VerifyQuery "skill designer"   # Such-Selbsttest
#   pwsh -File ingest.ps1 -IncludeThread <id>[,<id>...]   # Threads erzwingen
#
# Env/Defaults: MEMORY_INGEST_OUT, MEMORY_INGEST_DB, MEMPALACE_WING
# (Default freebuff_dev_setup). OutDir bewusst = Legacy-Export-Ordner
# (mine ist pro Quellpfad idempotent, kein Duplikat-Drawers); der State-JSON
# liegt eine Ebene darueber, damit mine ihn nicht mitliest.

param(
	[switch]$DryRun,
	[switch]$SkipMine,
	[string]$OutDir,
	[string]$DbPath,
	[string]$Wing,
	[string]$VerifyQuery,
	[string[]]$IncludeThread,
	[switch]$Force,
	[switch]$VerboseLog,
	[string]$LogPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $OutDir) { $OutDir = 'D:/mempalace/exports/freebuff-legacy-sessions' }
if (-not $Wing) { $Wing = if ($env:MEMPALACE_WING) { $env:MEMPALACE_WING } else { 'freebuff_dev_setup' } }
if (-not $LogPath) { $LogPath = Join-Path $scriptDir 'ingest.log' }

# Log mit Rotation (wie node-watchdog: >5 MB -> .1, nur ein Archiv)
$MaxLogBytes = 5MB
if (Test-Path $LogPath) {
	if ((Get-Item $LogPath).Length -gt $MaxLogBytes) {
		$archive = "$LogPath.1"
		if (Test-Path $archive) { Remove-Item -Path $archive -Force }
		Move-Item -Path $LogPath -Destination $archive -Force
	}
}
$transcriptActive = $false
try {
	Start-Transcript -Path $LogPath -Append -ErrorAction Stop | Out-Null
	$transcriptActive = $true
} catch {
	# Transcript optional (z. B. gesperrte Datei): Pipeline darf trotzdem laufen.
	Write-Host ("Hinweis: kein Transcript-Log ({0})" -f $_.Exception.Message)
}

function Stop-RunTranscript {
	if ($script:transcriptActive) {
		Stop-Transcript | Out-Null
		$script:transcriptActive = $false
	}
}

# ------------------------------------------------------------- 1) Export
$exportArgs = @('run', "$scriptDir/export.ts", '--out', $OutDir)
if ($DbPath) { $exportArgs += @('--db', $DbPath) }
if ($DryRun) { $exportArgs += '--dry-run' }
if ($Force) { $exportArgs += '--force' }
if ($VerboseLog) { $exportArgs += '--verbose' }
if ($IncludeThread -and $IncludeThread.Count -gt 0) {
	$exportArgs += @('--include-thread', ($IncludeThread -join ','))
}

Write-Host ("[1/3] Export: bun {0}" -f ($exportArgs -join ' '))
& bun @exportArgs
if ($LASTEXITCODE -ne 0) {
	Write-Host ("Export fehlgeschlagen (Exit {0})." -f $LASTEXITCODE) -ForegroundColor Red
	Stop-RunTranscript
	exit $LASTEXITCODE
}
if ($DryRun) {
	Write-Host 'DryRun: Pipeline hier beendet (kein Mine, kein Schreiben).'
	Stop-RunTranscript
	exit 0
}

# ------------------------------------------------------------- 2) Mine
if ($SkipMine) {
	Write-Host '[2/3] Mine uebersprungen (-SkipMine).'
} else {
	$mineArgs = @('mine', $OutDir, '--mode', 'convos', '--extract', 'general', '--wing', $Wing, '--agent', 'maxhambi')
	Write-Host ("[2/3] Mine: mempalace {0}" -f ($mineArgs -join ' '))
	& mempalace @mineArgs
	if ($LASTEXITCODE -ne 0) {
		Write-Host ("Mine fehlgeschlagen (Exit {0})." -f $LASTEXITCODE) -ForegroundColor Red
		Stop-RunTranscript
		exit $LASTEXITCODE
	}
}

# ------------------------------------------------------------- 3) Verify
if ($VerifyQuery) {
	Write-Host ("[3/3] Verify: mempalace search `"{0}`"" -f $VerifyQuery)
	& mempalace search $VerifyQuery
	if ($LASTEXITCODE -ne 0) {
		Write-Host ("Suche fehlgeschlagen (Exit {0})." -f $LASTEXITCODE) -ForegroundColor Red
		Stop-RunTranscript
		exit $LASTEXITCODE
	}
} else {
	Write-Host '[3/3] Verify uebersprungen (kein -VerifyQuery gesetzt).'
}

Write-Host 'Memory-Ingest abgeschlossen.'
Stop-RunTranscript
exit 0
