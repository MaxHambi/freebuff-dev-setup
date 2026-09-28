# 30-ErrorHandling.ps1 - Fehlerklassifikation fuer die NextDNS-API.
#
# API-Modell (docs/nextdns-api.md):
#   200/400 liefern entweder {"data":..., "meta":...} oder {"errors":[...]}.
#   400 + errors[] = Client-Fehler (Query/Body).
#   200 OK + errors[] = USER-Fehler (z. B. ungueltige Domain in Denylist)
#     -> ist KEIN Erfolg und muss als Fehler ausgewiesen werden.

function Get-NextDnsErrorDetail {
	<#
	.SYNOPSIS
		Aggregiert ein errors[]-Array zu einem kompakten, lesbaren String.
	#>
	[CmdletBinding()]
	param(
		[AllowNull()]
		[object[]]$Errors
	)
	if (-not $Errors -or @($Errors).Count -eq 0) { return '' }

	$parts = foreach ($e in $Errors) {
		if ($null -eq $e) { continue }
		$code = $e.code
		$detail = $e.detail
		$source = ''
		if ($e.source) {
			if ($e.source.parameter) { $source = "param=$($e.source.parameter)" }
			elseif ($e.source.pointer) { $source = "pointer=$($e.source.pointer)" }
		}
		$line = "[$code] $detail"
		if ($source) { $line += " ($source)" }
		$line.Trim()
	}
	return (($parts | Where-Object { $_ }) -join '; ')
}

function Resolve-NextDnsApiResult {
	<#
	.SYNOPSIS
		Klassifiziert einen API-Antwortkoerper. Liefert ein Result-Objekt:
		Ok=$false, wenn HTTP-Fehler ODER errors[] im Body vorhanden sind.
	#>
	[CmdletBinding()]
	param(
		[int]$StatusCode = 200,
		[AllowNull()][object]$Body,
		[AllowNull()][string]$TransportError
	)

	# 1) Transport-/HTTP-Fehler (aus dem Catch des Calls)
	if (-not [string]::IsNullOrWhiteSpace($TransportError)) {
		return [PSCustomObject]@{ Ok = $false; Status = $StatusCode; Data = $null; Meta = $null; Error = $TransportError }
	}

	# 2) HTTP-Fehlerstatus
	if ($StatusCode -ge 400) {
		$detail = ''
		if ($Body -and $Body.PSObject.Properties['errors']) {
			$detail = Get-NextDnsErrorDetail -Errors $Body.errors
		}
		if (-not $detail) { $detail = "HTTP $StatusCode" }
		return [PSCustomObject]@{ Ok = $false; Status = $StatusCode; Data = $null; Meta = $null; Error = $detail }
	}

	# 3) Body-Fehler: errors[] im Body = Fehler, unabhaengig vom Status
	#    (200 OK + errors[] ist der USER-Fehler-Fall der API!)
	if ($Body -and $Body.PSObject.Properties['errors'] -and @($Body.errors).Count -gt 0) {
		$detail = Get-NextDnsErrorDetail -Errors $Body.errors
		return [PSCustomObject]@{ Ok = $false; Status = $StatusCode; Data = $null; Meta = $null; Error = $detail }
	}

	# 4) Erfolg: data extrahieren (Envelope), Meta mitnehmen
	$data = $null
	$meta = $null
	if ($Body) {
		if ($Body.PSObject.Properties['data']) { $data = $Body.data }
		else { $data = $Body }
		if ($Body.PSObject.Properties['meta']) { $meta = $Body.meta }
	}

	return [PSCustomObject]@{ Ok = $true; Status = $StatusCode; Data = $data; Meta = $meta; Error = $null }
}
