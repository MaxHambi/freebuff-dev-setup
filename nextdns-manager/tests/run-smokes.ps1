#Requires -Version 7.4
# run-smokes.ps1 - Runner fuer alle Dauer-Smokes (zusaetzliche Pruefschicht
# NEBEN der Pester-Suite, Operator-Anforderung Issue #42).
#
# Jeder Smoke laeuft in einem eigenen pwsh-Prozess mit Haerte-Timeout
# (30 s): Confirm-Prompts oder Haengs brechen ab statt zu blockieren.
#
# Exit-Codes: 0 = alle gruen, 1 = mindestens ein Smoke fehlgeschlagen.

[CmdletBinding()]
param([switch]$Quiet)

$ErrorActionPreference = 'Stop'
$smokeDir = Join-Path -Path $PSScriptRoot -ChildPath 'smokes'
$smokes = Get-ChildItem -Path $smokeDir -Filter '*-Smoke.ps1' -File | Sort-Object Name

$failed = @()
$total = 0
foreach ($smoke in $smokes) {
	$total++
	$name = $smoke.BaseName
	$smokeFile = $smoke.FullName
	$job = Start-Job -ScriptBlock {
		& pwsh -NoProfile -File $using:smokeFile 2>&1
	}

	$done = Wait-Job $job -Timeout 30
	if (-not $done) {
		Stop-Job $job -ErrorAction SilentlyContinue
		$failed += $name
		Write-Host ("FAIL {0} (Timeout 30 s - moeglicher Hang/Prompt)" -f $name) -ForegroundColor Red
	} else {
		$output = Receive-Job $job
		$state = $job.State
		if ($state -eq 'Completed' -and $output -and ($output | Select-Object -Last 1) -match 'grun\b|gruen\b') {
			if (-not $Quiet) { $output | ForEach-Object { Write-Host ("  {0}" -f $_) } }
			Write-Host ("PASS {0}" -f $name) -ForegroundColor Green
		} else {
			$failed += $name
			Write-Host ("FAIL {0} (Exit {1})" -f $name, $state) -ForegroundColor Red
			$output | Select-Object -Last 8 | ForEach-Object { Write-Host ("  {0}" -f $_) -ForegroundColor Red }
		}
	}
	Remove-Job $job -Force -ErrorAction SilentlyContinue
}

Write-Host ''
if ($failed) {
	Write-Host ("{0} von {1} Smoke(s) fehlgeschlagen: {2}" -f $failed.Count, $total, ($failed -join ', ')) -ForegroundColor Red
	exit 1
}
Write-Host ("Alle {0} Smokes gruen." -f $total) -ForegroundColor Green
exit 0
