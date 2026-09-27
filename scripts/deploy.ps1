#Requires -Version 5.1
# Deploy: spiegelt die Skript-Ordner aus dem Repo nach %USERPROFILE%\.tools.
# Merge-Logik: bestehende Dateien werden NUR ueberschrieben, wenn -Force gesetzt ist.
# Implementierungs-Sitzung: Reihenfolge/Stop der Tasks laut plan.md (Slices T2-T6).

param(
	[switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Split-Path -Parent $PSScriptRoot
$targetRoot = Join-Path $env:USERPROFILE '.tools'
$folders = @('node-watchdog', 'node-monitor', 'maintenance', 'routed-watch', 'ruflo-policy-rotate', 'memory-ingest')

foreach ($folder in $folders) {
	$src = Join-Path $repoRoot $folder
	if (-not (Test-Path $src)) {
		Write-Host ("SKIP {0} (noch nicht im Repo)" -f $folder)
		continue
	}
	$dst = Join-Path $targetRoot $folder
	New-Item -ItemType Directory -Force -Path $dst | Out-Null		# Runtime-Logs nicht ueberschreiben (gehören der laufenden Task)
		foreach ($file in Get-ChildItem -Path $src -File | Where-Object { $_.Extension -ne '.log' }) {
		$targetFile = Join-Path $dst $file.Name
		if ((Test-Path $targetFile) -and -not $Force) {
			Write-Host ("KEEP {0}\{1} (existiert, -Force zum Ueberschreiben)" -f $folder, $file.Name)
			continue
		}
		Copy-Item -Path $file.FullName -Destination $targetFile -Force
		Write-Host ("COPY {0}\{1}" -f $folder, $file.Name)
	}
}

Write-Host ("Deploy-Ziel: {0}" -f $targetRoot)
exit 0
