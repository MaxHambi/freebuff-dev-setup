#Requires -Version 5.1
# agenttrace-Session-Audit (advisory): erstellt vor jedem Push einen
# Health-Bericht ueber die lokalen AI-Coding-Sessions und warnt bei
# kritischen Anomalien bzw. Health unter dem Schwellwert.
#
# Bewusst NICHT blockierend: Der Exit-Code ist immer 0 (Skip oder Warn),
# der pre-push-Hook macht daraus nur einen Warnblock. Schwellwerte
# anpassen, sobald die Baseline bekannt ist (Skill-Empfehlung: advisory
# starten, dann schaerfen).
#
# Aufruf:
#   pwsh -File scripts/agenttrace-audit.ps1
#   pwsh -File scripts/agenttrace-audit.ps1 -MinHealth 80   # Grenze anheben
#   pwsh -File scripts/agenttrace-audit.ps1 -NoFailOnCritical   # nur Bericht
#
# Report: out/agenttrace-overview.md (gitignored)

param(
	[int]$MinHealth = 70,
	[switch]$NoFailOnCritical
)

$ErrorActionPreference = 'Continue'

function Resolve-Agenttrace {
	$cmd = Get-Command agenttrace.exe -ErrorAction SilentlyContinue
	if ($cmd) { return $cmd.Source }
	$local = Join-Path $env:LOCALAPPDATA 'agenttrace\agenttrace.exe'
	if (Test-Path $local) { return $local }
	return $null
}

function Out-Advisory {
	param([string]$Level, [string]$Text)
	$line = "agenttrace-advisory: [$Level] $Text"
	Write-Host $line
	Add-Content -Path $outFile -Value ''
	Add-Content -Path $outFile -Value $line
}

$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$outDir = Join-Path $repoRoot 'out'
$outFile = Join-Path $outDir 'agenttrace-overview.md'
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }
Set-Content -Path $outFile -Value ("# agenttrace Session-Audit - {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))

$bin = Resolve-Agenttrace
if (-not $bin) {
	Out-Advisory 'SKIP' ('agenttrace nicht gefunden (erwartet: %LOCALAPPDATA%\agenttrace\agenttrace.exe) - Bericht uebersprungen, Gate bleibt gruen.')
	exit 0
}

if ($NoFailOnCritical) {
	& $bin --overview -f markdown -o $outFile | Out-Null
}
else {
	& $bin --overview --fail-under-health $MinHealth --fail-on-critical -f markdown -o $outFile | Out-Null
}
$exitCode = $LASTEXITCODE

if (-not (Test-Path $outFile)) {
	Out-Advisory 'SKIP' 'agenttrace lief, erzeugte aber keinen Report - nichts gewarnt, Gate bleibt gruen.'
	exit 0
}

if ($exitCode -eq 0) {
	Write-Host 'agenttrace-advisory: [OK] Session-Health im Rahmen - Bericht: out/agenttrace-overview.md'
	exit 0
}

$summary = (Get-Content -Path $outFile -TotalCount 12) -join ' '
Out-Advisory 'WARN' ("Schwellwert verletzt (Exit {0}). Bericht: out/agenttrace-overview.md. Kopf: {1}" -f $exitCode, $summary)
Write-Host 'agenttrace-advisory: Push laeuft weiter (advisory). Vor dem Schaerfen: Baseline mit -MinHealth anheben.'
exit 0
