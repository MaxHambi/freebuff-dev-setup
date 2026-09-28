# 50-Pagination.ps1 - Limit-Clamps und Folgeseiten-Sammlung mit Dedupe.
#
# Limits laut API-Doku (docs/nextdns-api.md):
#   Logs: 10..1000 (Default 100) | Analytics: 1..500 (Default 10)

function Get-NextDnsClampedLimit {
	<#
	.SYNOPSIS
		Clamped einen Limit-Wert auf [Min, Max] (PLAN Befund 4).
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)][int]$Limit,
		[Parameter(Mandatory)][int]$Min,
		[Parameter(Mandatory)][int]$Max
	)
	if ($Limit -lt $Min) { return $Min }
	if ($Limit -gt $Max) { return $Max }
	return $Limit
}

function Get-NextDnsPaginationCursor {
	<#
	.SYNOPSIS
		Extrahiert meta.pagination.cursor (oder $null).
	#>
	[CmdletBinding()]
	param([AllowNull()][object]$Meta)
	if ($Meta -and $Meta.PSObject.Properties['pagination'] -and $Meta.pagination -and
		$Meta.pagination.PSObject.Properties['cursor']) {
		return $Meta.pagination.cursor
	}
	return $null
}

function Get-NextDnsAllPages {
	<#
	.SYNOPSIS
		Sammelt alle Folgeseiten eines paginierten Endpoints. Dedupe per
		Id-Hashtabelle (Cursor-Wiederholung/Reihenfolge-Artefakte entsch-
		aeft; PLAN Befund 4). Dedupe-Key: erste Identaehits-Eigenschaft
		(id/timestamp/domain) - ohne Treffer wird der Eintrag behalten.
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)][string]$Endpoint,
		[int]$PageLimit = 1000,
		[int]$MaxPages = 100,
		[int]$SleepMs = 200,
		[int]$MaxEntries = 0
	)

	$cfg = Get-NextDnsConfig
	$collected = [System.Collections.Generic.List[object]]::new()
	$seen = @{}
	$cursor = $null
	$page = 0
	$transportError = $null

	do {
		$page++
		$sep = if ($Endpoint -match '\?') { '&' } else { '?' }
		$ep = "$Endpoint${sep}limit=$PageLimit"
		if ($cursor) {
			$encoded = [System.Uri]::EscapeDataString($cursor)
			$ep += "&cursor=$encoded"
		}

		$result = Invoke-NextDnsApi -Method 'GET' -Endpoint $ep
		if (-not $result.Ok) {
			$transportError = $result.Error
			break
		}

		$added = 0
		if ($null -ne $result.Data) {
			foreach ($entry in @($result.Data)) {
				$key = $null
				if ($entry -and $entry.PSObject.Properties['id']) { $key = "id:$($entry.id)" }
				elseif ($entry -and $entry.PSObject.Properties['timestamp'] -and $entry.PSObject.Properties['domain']) {
					$key = "td:$($entry.timestamp)|$($entry.domain)"
				}
				if ($key) {
					if ($seen.ContainsKey($key)) { continue }
					$seen[$key] = $true
				}
				$collected.Add($entry)
				$added++
				if ($MaxEntries -gt 0 -and $collected.Count -ge $MaxEntries) { break }
			}
		}

		$cursor = Get-NextDnsPaginationCursor -Meta $result.Meta

		if ($MaxEntries -gt 0 -and $collected.Count -ge $MaxEntries) { break }
		if ($cursor -and $page -lt $MaxPages -and $SleepMs -gt 0) {
			Start-Sleep -Milliseconds $SleepMs
		}
	} while ($cursor -and $page -lt $MaxPages)

	return [PSCustomObject]@{
		Entries = $collected
		Pages = $page
		Error = $transportError
		Truncated = ($MaxEntries -gt 0 -and $collected.Count -ge $MaxEntries)
	}
}
