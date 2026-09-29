# mirror-sync.ps1 - Sync-/Integritaets-Header fuer Issue-Mirrors (docs/issues/)
#
# Contract (je Mirror-Datei, Zeile 2 direkt nach der H1-UEberschrift):
#   <!-- mirror-sync: source=github:MaxHambi/freebuff-dev-setup#NN sha256:<hex64> synced=<ISO8601> -->
#
# sha256 = SHA-256 ueber den UTF-8-Bytes des GitHub-Issue-BODY im Moment des
# Syncs. Der Mirror-Text bleibt handgepflegt; der Header belegt nur, gegen
# welchen Quellstand gespiegelt wurde. -Check erkennt Drift (Quelle geaendert
# seit Sync). Geloeschte Issues (404) bekommen sha256:gone und gelten als
# sauber gespiegelt (Mirror-first-Regel: Mirrors ueberleben Loeschungen).
#
# Beispiele:
#   pwsh -File scripts/mirror-sync.ps1                 # Pruefen + Report
#   pwsh -File scripts/mirror-sync.ps1 -Check          # streng: Exit 1 bei Drift/fehlendem Header
#   pwsh -File scripts/mirror-sync.ps1 -Update         # Header stempeln/auffrischen
[CmdletBinding()]
param(
	[string]$Path = 'docs/issues',
	[switch]$Check,
	[switch]$Update
)

$ErrorActionPreference = 'Stop'
$Repo = 'MaxHambi/freebuff-dev-setup'
$HeaderPattern = '<!--\s*mirror-sync:\s*source=github:[^\s#]+#(?<num>\d+)\s+sha256:(?<sha>[0-9a-f]{64}|gone)\s+synced=(?<ts>[^\s>]+)\s*-->'

function Get-Sha256Hex([string]$Text) {
	$bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
	$sha = [System.Security.Cryptography.SHA256]::Create()
	try { ([System.BitConverter]::ToString($sha.ComputeHash($bytes)) -replace '-', '').ToLowerInvariant() }
	finally { $sha.Dispose() }
}

function Get-GitHubIssue([int]$Number) {
	$json = & gh api "repos/$Repo/issues/$Number" 2>$null
	if ($LASTEXITCODE -ne 0 -or -not $json) { return $null }
	$obj = ($json -join "`n") | ConvertFrom-Json
	@{ title = [string]$obj.title; state = [string]$obj.state; body = [string]$obj.body }
}

$results = [System.Collections.Generic.List[string]]::new()
$fail = 0
$gone = 0
$synced = 0

$files = @(Get-ChildItem -Path $Path -Filter 'issue-*.md' -File | Sort-Object Name)
if ($files.Count -eq 0) { Write-Error "Keine issue-*.md unter '$Path' gefunden."; exit 2 }

foreach ($file in $files) {
	if ($file.Name -notmatch '^issue-(\d+)\.md$') {
		$results.Add("SKIP    $($file.Name) (keine Issue-Nummer im Dateinamen)")
		continue
	}
	$n = [int]$Matches[1]
	$content = Get-Content -Path $file.FullName -Raw
	$hasHeader = $content -match $HeaderPattern
	$oldSha = if ($hasHeader) { $Matches['sha'] } else { '' }

	$issue = Get-GitHubIssue $n
	if (-not $issue) {
		# Quelle nicht (mehr) abrufbar: 404/loeschung -> gone vermerken
		if ($oldSha -eq 'gone') {
			$results.Add("GONE    $($file.Name) (Quelle geloescht, Header schon auf gone)")
			continue
		}
		if ($Update) {
			$stamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
			$header = "<!-- mirror-sync: source=github:$Repo#$n sha256:gone synced=$stamp -->"
			if ($hasHeader) {
				$content = $content -replace $HeaderPattern, $header
			} else {
				$lines = $content -split "`r?`n", 2
				$content = ($lines[0] + "`n" + $header + "`n" + $lines[1])
			}
			Set-Content -Path $file.FullName -Value $content -NoNewline -Encoding utf8
			$gone++
			$results.Add("GONE    $($file.Name) (Quelle nicht abrufbar -> Header auf gone gesetzt)")
		} else {
			$fail++
			$results.Add("FAIL    $($file.Name) (Quelle #$n nicht abrufbar; alter sha=$(if($oldSha){$oldSha}else{'-'}))")
		}
		continue
	}

	$sha = Get-Sha256Hex $issue.body
	if ($oldSha -eq $sha) {
		$results.Add("OK      $($file.Name) (sha stimmt, Quelle #$n [$($issue.state)])")
		continue
	}

	if ($Update) {
		$stamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
		$header = "<!-- mirror-sync: source=github:$Repo#$n sha256:$sha synced=$stamp -->"
		if ($hasHeader) {
			$content = $content -replace $HeaderPattern, $header
		} else {
			$lines = $content -split "`r?`n", 2
			$content = ($lines[0] + "`n" + $header + "`n" + $lines[1])
		}
		Set-Content -Path $file.FullName -Value $content -NoNewline -Encoding utf8
		$synced++
		if ($hasHeader) {
			$results.Add("DRIFT   $($file.Name) -> Header aufgefrischt (Quelle #$n geaendert seit letztem Sync; Mirror-Inhalt gegenlesehen!)")
		} else {
			$results.Add("STAMP   $($file.Name) -> Header neu gesetzt (Quelle #$n [$($issue.state)])")
		}
	} else {
		$fail++
		$kind = if ($hasHeader) { 'Drift: Quelle geaendert seit Sync' } else { 'Header fehlt (nie gespiegelt-stempeln mit -Update)' }
		$results.Add("FAIL    $($file.Name) ($kind; Quell-sha=$sha)")
	}
}

$results | ForEach-Object { Write-Host $_ }
$summary = "mirror-sync: $($files.Count) Mirrors, $synced gestempelt, $gone gone, $fail FAIL"
Write-Host $summary
if ($Check -and $fail -gt 0) { exit 1 }
exit 0
