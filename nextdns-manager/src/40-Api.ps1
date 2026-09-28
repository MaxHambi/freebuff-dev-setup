# 40-Api.ps1 - einheitlicher API-Call mit Retry, 429/Retry-After und
# errors[]-Klassifikation (Resolve-NextDnsApiResult).
#
# Seam fuer Tests: Set-NextDnsHttpDelegate setzt ein ScriptBlock-Delegate,
# das statt Invoke-NextDnsHttpRequest aufgerufen wird (module-lokaler Scope,
# von Tests aus via Set-NextDnsHttpDelegate erreichbar). Rueckgabe-Contract:
# PSCustomObject { StatusCode; Content; Headers; TransportError }.

$script:NextDnsHttpDelegate = $null

function Set-NextDnsHttpDelegate {
	<#
	.SYNOPSIS
		Setzt/entfernt (Delegate=$null) den HTTP-Test-Delegat.
	#>
	[CmdletBinding()]
	param([AllowNull()][ScriptBlock]$Delegate)
	$script:NextDnsHttpDelegate = $Delegate
}

function Invoke-NextDnsHttpRequest {
	<#
	.SYNOPSIS
		Duenner HTTP-Wrapper (Test-Seam). Liefert PSCustomObject
		{ StatusCode; Content; Headers; TransportError }.
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)][string]$Uri,
		[Parameter(Mandatory)][ValidateSet('GET', 'POST', 'PATCH', 'PUT', 'DELETE')][string]$Method,
		[hashtable]$Headers,
		[string]$JsonBody,
		[int]$TimeoutSec = 30
	)
	try {
		$params = @{
			Uri = $Uri
			Method = $Method
			Headers = $Headers
			TimeoutSec = $TimeoutSec
			ErrorAction = 'Stop'
		}
		if ($JsonBody) { $params.Body = $JsonBody }
		$resp = Invoke-WebRequest @params
		return [PSCustomObject]@{
			StatusCode = [int]$resp.StatusCode
			Content = $resp.Content
			Headers = $resp.Headers
			TransportError = $null
		}
	} catch {
		# Status und Header GETRENNT extrahieren: ein wirfender Headers-Zugriff
		# darf den bereits ermittelten StatusCode nicht zuruecksetzen (sonst
		# wuerde ein 4xx als Netzwerkfehler mit Status 0 klassifiziert und
		# faelschlicherweise retryiert).
		$status = 0
		$headers = $null
		try { if ($_.Exception.Response) { $status = [int]$_.Exception.Response.StatusCode } } catch { }
		try { if ($_.Exception.Response) { $headers = $_.Exception.Response.Headers } } catch { }

		$detail = ''
		try { if ($_.ErrorDetails.Message) { $detail = ($_.ErrorDetails.Message -replace '\s+', ' ').Trim() } } catch { $detail = '' }
		$transport = "HTTP $status - $($_.Exception.Message)"
		if ($detail) { $transport += " | $detail" }

		return [PSCustomObject]@{
			StatusCode = $status
			Content = $detail
			Headers = $headers
			TransportError = $transport
		}
	}
}

function Invoke-NextDnsApi {
	<#
	.SYNOPSIS
		Fuehrt einen NextDNS-API-Call aus und liefert IMMER ein Result-
		Objekt (Resolve-NextDnsApiResult): Ok/Status/Data/Meta/Error.
	#>
	[CmdletBinding()]
	param(
		[ValidateSet('GET', 'POST', 'PATCH', 'PUT', 'DELETE')][string]$Method = 'GET',
		[Parameter(Mandatory)][string]$Endpoint,
		[object]$Body,
		[int]$MaxRetries = 2,
		[int]$TimeoutSec = 30
	)

	$cfg = Get-NextDnsConfig
	Assert-NextDnsConfigReady

	$uri = $cfg.BaseUrl.TrimEnd('/') + $Endpoint
	$headers = @{
		'X-Api-Key' = $cfg.ApiKey
		'Accept' = 'application/json'
	}
	$jsonBody = $null
	if ($null -ne $Body) { $jsonBody = $Body | ConvertTo-Json -Depth 10 -Compress }

	$attempt = 0
	$lastTransport = $null
	$lastStatus = 0
	while ($attempt -le $MaxRetries) {
		$attempt++
		if ($script:NextDnsHttpDelegate) {
			$resp = & $script:NextDnsHttpDelegate -Uri $uri -Method $Method -Headers $headers -JsonBody $jsonBody -TimeoutSec $TimeoutSec
		} else {
			$resp = Invoke-NextDnsHttpRequest -Uri $uri -Method $Method -Headers $headers -JsonBody $jsonBody -TimeoutSec $TimeoutSec
		}

		if (-not $resp.TransportError) {
			$parsed = $null
			if (-not [string]::IsNullOrWhiteSpace($resp.Content)) {
				try { $parsed = $resp.Content | ConvertFrom-Json } catch { $parsed = $null }
			}
			return (Resolve-NextDnsApiResult -StatusCode $resp.StatusCode -Body $parsed)
		}

		$lastTransport = $resp.TransportError
		$lastStatus = $resp.StatusCode

		# Retry nur bei Netzwerkfehlern (Status 0), 429 und 5xx
		$retryable = ($lastStatus -eq 0) -or ($lastStatus -eq 429) -or ($lastStatus -ge 500)
		if ($retryable -and $attempt -le $MaxRetries) {
			$delay = 2
			if ($lastStatus -eq 429) {
				# Retry-After respektieren (Sekunden; Fallback 2 s) - PLAN Befund 3
				$ra = $null
				try { $ra = $resp.Headers['Retry-After'] } catch { $ra = $null }
				if ($ra) {
					$parsed = 0
					if ([int]::TryParse(($ra | Select-Object -First 1), [ref]$parsed) -and $parsed -gt 0) { $delay = $parsed }
				}
			}
			Write-Verbose ("Retry {0}/{1} nach HTTP {2}, warte {3}s" -f $attempt, $MaxRetries, $lastStatus, $delay)
			Start-Sleep -Seconds $delay
			continue
		}
		break
	}

	return (Resolve-NextDnsApiResult -StatusCode $lastStatus -Body $null -TransportError $lastTransport)
}
