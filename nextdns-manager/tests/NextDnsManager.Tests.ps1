# Pester-Suite fuer den NextDNS-Manager (Issue #42).
#
# Deckt ab (gemockt ueber Set-NextDnsHttpDelegate, KEINE Live-Calls):
#   - Error-Parsing: 400+errors[], 200 OK + errors[] = FEHLER (PLAN Befund 1)
#   - 429/Retry-After, Retry nur bei Netzwerk/429/5xx (Befund 3)
#   - Limit-Clamps Logs 10..1000 / Analytics 1..500 (Befund 4)
#   - Pagination-Dedupe bei Cursor-Wiederholung (Befund 4)
#   - Dimensions-Registry: reasons ohne type, destinations mit type-Pflicht (Befund 2)
#   - Logs-Filter-Satz im Endpoint
#   - Dispatch-Tabelle (vollstaendig, Keys eindeutig, Funktionen existieren)
#   - Write-Safety: WhatIf ohne HTTP-Call, errors[] je Domain, ConfirmImpact=High
#   - Font-Erkennung (Icon-Modi)
#   - HTTP-Request-Contract: ContentType application/json bei JSON-Body,
#     keiner bei Body-losen Calls (Issue #65, live bewiesen 2026-09-29)

BeforeAll {
	$modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\NextDnsManager.psd1'
	Import-Module $modulePath -Force
	$null = Initialize-NextDnsConfig -ApiKey 'testkey123' -ProfileId 'abc123'

	# Delegate-Helfer: ScriptBlock als Mock-HTTP-Handler setzen
	function Set-MockHttp([scriptblock]$Handler) {
		Set-NextDnsHttpDelegate -Delegate $Handler
	}
}

AfterAll {
	Set-NextDnsHttpDelegate -Delegate $null
	Remove-Module NextDnsManager -ErrorAction SilentlyContinue
}

Describe 'ErrorHandling (Befund 1)' {
	It 'bewertet 200 OK + errors[] als FEHLER mit Detail' {
		Set-MockHttp {
			param($Uri, $Method, $Headers, $JsonBody, $TimeoutSec)
			[PSCustomObject]@{ StatusCode = 200; Content = '{"errors":[{"code":"invalid","detail":"badwebsite is not a valid domain"}]}'; Headers = $null; TransportError = $null }
		}
		$r = Invoke-NextDnsApi -Method 'POST' -Endpoint '/profiles/abc123/denylist' -Body @{ id = 'badwebsite'; active = $true }
		$r.Ok | Should -BeFalse
		$r.Error | Should -Match 'not a valid domain'
	}

	It 'loest den data-Envelope auf und liefert meta mit' {
		Set-MockHttp {
			param($Uri, $Method, $Headers, $JsonBody, $TimeoutSec)
			[PSCustomObject]@{ StatusCode = 200; Content = '{"data":[{"id":"x"}],"meta":{"pagination":{"cursor":"next"}}}'; Headers = $null; TransportError = $null }
		}
		$r = Invoke-NextDnsApi -Method 'GET' -Endpoint '/profiles/abc123/denylist'
		$r.Ok | Should -BeTrue
		@($r.Data).Count | Should -Be 1
		(Get-NextDnsPaginationCursor -Meta $r.Meta) | Should -Be 'next'
	}

	It 'bewertet 400 + errors[] als Fehler' {
		Set-MockHttp {
			param($Uri, $Method, $Headers, $JsonBody, $TimeoutSec)
			[PSCustomObject]@{ StatusCode = 0; Content = '{"errors":[{"code":"invalid","detail":"limit"}]}'; Headers = $null; TransportError = 'HTTP 400 - bad request' }
		}
		$r = Invoke-NextDnsApi -Method 'GET' -Endpoint '/profiles/abc123/analytics/status' -MaxRetries 0
		$r.Ok | Should -BeFalse
	}
}

Describe 'Retry/Rate-Limit (Befund 3)' {
	It 'retryiert bei Netzwerkfehler und erholt sich' {
		$script:calls429 = 0
		Set-MockHttp {
			param($Uri, $Method, $Headers, $JsonBody, $TimeoutSec)
			$script:calls429++
			if ($script:calls429 -eq 1) {
				[PSCustomObject]@{ StatusCode = 0; Content = ''; Headers = $null; TransportError = 'HTTP 429 - rate limited' }
			} else {
				[PSCustomObject]@{ StatusCode = 200; Content = '{"data":[{"id":"ok"}]}'; Headers = $null; TransportError = $null }
			}
		}
		$r = Invoke-NextDnsApi -Method 'GET' -Endpoint '/profiles/abc123/status' -MaxRetries 2
		$script:calls429 | Should -Be 2
		$r.Ok | Should -BeTrue
	}

	It 'retryiert NICHT bei 4xx' {
		$script:calls403 = 0
		Set-MockHttp {
			param($Uri, $Method, $Headers, $JsonBody, $TimeoutSec)
			$script:calls403++
			[PSCustomObject]@{ StatusCode = 403; Content = '{"errors":[{"code":"authRequired"}]}'; Headers = $null; TransportError = 'HTTP 403 - forbidden | authRequired' }
		}
		$r = Invoke-NextDnsApi -Method 'GET' -Endpoint '/profiles/abc123' -MaxRetries 2
		$script:calls403 | Should -Be 1
		$r.Ok | Should -BeFalse
		$r.Error | Should -Match 'authRequired'
	}

	It 'leakt das Secret nicht in Fehlermeldungen' {
		Set-MockHttp {
			param($Uri, $Method, $Headers, $JsonBody, $TimeoutSec)
			[PSCustomObject]@{ StatusCode = 0; Content = ''; Headers = $null; TransportError = 'boom' }
		}
		$r = Invoke-NextDnsApi -Method 'GET' -Endpoint '/profiles/abc123' -MaxRetries 0
		$r.Error | Should -Not -Match 'testkey123'
	}
}

Describe 'Limit-Clamps (Befund 4)' {
	It 'clamped Analytics auf 1..500' {
		(Get-NextDnsClampedLimit -Limit 9999 -Min 1 -Max 500) | Should -Be 500
		(Get-NextDnsClampedLimit -Limit 0 -Min 1 -Max 500) | Should -Be 1
		(Get-NextDnsClampedLimit -Limit 25 -Min 1 -Max 500) | Should -Be 25
	}

	It 'clamped Logs-Endpoint auf 10..1000' {
		Set-MockHttp {
			param($Uri, $Method, $Headers, $JsonBody, $TimeoutSec)
			$script:logUri = $Uri
			[PSCustomObject]@{ StatusCode = 200; Content = '{"data":[]}'; Headers = $null; TransportError = $null }
		}
		$null = Get-NextDnsLogs -Limit 9999
		$script:logUri | Should -Match 'limit=1000'
		$null = Get-NextDnsLogs -Limit 3
		$script:logUri | Should -Match 'limit=10'
	}
}

Describe 'Pagination-Dedupe (Befund 4)' {
	It 'entschaeft Cursor-Wiederholung ohne Doppel-Eintraege' {
		Set-MockHttp {
			param($Uri, $Method, $Headers, $JsonBody, $TimeoutSec)
			if ($Uri -match 'cursor=') {
				[PSCustomObject]@{ StatusCode = 200; Content = '{"data":[{"id":"a"},{"id":"c"}],"meta":{"pagination":{"cursor":null}}}'; Headers = $null; TransportError = $null }
			} else {
				[PSCustomObject]@{ StatusCode = 200; Content = '{"data":[{"id":"a"},{"id":"b"}],"meta":{"pagination":{"cursor":"cur1"}}}'; Headers = $null; TransportError = $null }
			}
		}
		$all = Get-NextDnsAllPages -Endpoint '/profiles/abc123/logs' -PageLimit 2 -SleepMs 0
		$all.Entries.Count | Should -Be 3
		@($all.Entries | ForEach-Object { $_.id } | Sort-Object -Unique).Count | Should -Be 3
		$all.Error | Should -BeNullOrEmpty
	}
}

Describe 'Analytics-Registry (Befund 2)' {
	It 'setzt bei reasons bewusst KEINEN type-Parameter' {
		$ep = Get-NextDnsAnalyticsEndpoint -Dimension 'reasons'
		$ep | Should -Be '/profiles/abc123/analytics/reasons?limit=10'
	}

	It 'erzwingt type=countries|gafam bei destinations (Default countries)' {
		$ep = Get-NextDnsAnalyticsEndpoint -Dimension 'destinations'
		$ep | Should -Match 'type=countries'
		{ Get-NextDnsAnalyticsEndpoint -Dimension 'destinations' -Type 'ungueltig' } | Should -Throw
	}

	It 'unterstuetzt domains mit status/root und ips' {
		$ep = Get-NextDnsAnalyticsEndpoint -Dimension 'domains' -Status 'blocked' -Root
		$ep | Should -Match 'status=blocked'
		$ep | Should -Match 'root=true'
		$epIps = Get-NextDnsAnalyticsEndpoint -Dimension 'ips'
		$epIps | Should -Match '/analytics/ips\?'
	}

	It 'haengt ;series an, wenn angefordert' {
		$ep = Get-NextDnsAnalyticsEndpoint -Dimension 'status' -Series
		$ep | Should -Match 'analytics/status;series\?'
	}

	It 'clamped Analytics-Limit im Endpoint' {
		$ep = Get-NextDnsAnalyticsEndpoint -Dimension 'status' -Limit 9999
		$ep | Should -Match 'limit=500'
	}
}

Describe 'Logs-Filter-Satz' {
	BeforeAll {
		Set-MockHttp {
			param($Uri, $Method, $Headers, $JsonBody, $TimeoutSec)
			$script:capturedLogUri = $Uri
			[PSCustomObject]@{ StatusCode = 200; Content = '{"data":[]}'; Headers = $null; TransportError = $null }
		}
	}

	It 'uebertraegt alle Filter in die Query' {
		$null = Get-NextDnsLogs -Status 'blocked' -Search 'facebook' -Device 'DEV1' -From '-24h' -Sort 'asc' -Raw
		$u = $script:capturedLogUri
		$u | Should -Match 'status=blocked'
		$u | Should -Match 'search=facebook'
		$u | Should -Match 'device=DEV1'
		$u | Should -Match 'from=-24h'
		$u | Should -Match 'sort=asc'
		$u | Should -Match 'raw=1'
	}
}

Describe 'Read-Funktionen (gemockt)' {
	It 'liefert Profil-Liste und Einzel-Profil' {
		Set-MockHttp {
			param($Uri, $Method, $Headers, $JsonBody, $TimeoutSec)
			if ($Uri -match '/profiles$') {
				[PSCustomObject]@{ StatusCode = 200; Content = '{"data":[{"id":"abc123","name":"Home"}]}'; Headers = $null; TransportError = $null }
			} else {
				[PSCustomObject]@{ StatusCode = 200; Content = '{"data":{"id":"abc123","name":"Home"}}'; Headers = $null; TransportError = $null }
			}
		}
		$profiles = Get-NextDnsProfiles
		$profileResult = Get-NextDnsProfile
		$profiles.Ok | Should -BeTrue
		$profileResult.Ok | Should -BeTrue
		$profileResult.Data.name | Should -Be 'Home'
	}

	It 'liefert Verbindungs-Diagnose' {
		Set-MockHttp {
			param($Uri, $Method, $Headers, $JsonBody, $TimeoutSec)
			if ($Uri -match '/profiles$') {
				[PSCustomObject]@{ StatusCode = 200; Content = '{"data":[{"id":"abc123","name":"Home"}]}'; Headers = $null; TransportError = $null }
			} else {
				[PSCustomObject]@{ StatusCode = 200; Content = '{"data":{"id":"abc123","name":"Home"}}'; Headers = $null; TransportError = $null }
			}
		}
		$diag = Test-NextDnsConnection
		$diag.Ok | Should -BeTrue
		$diag.ProfileCount | Should -Be 1
		$diag.ActiveProfile.name | Should -Be 'Home'
	}
}

Describe 'Write-Safety (Befund 1/6)' {
	BeforeEach {
		$script:writeCalls = @()
		Set-MockHttp {
			param($Uri, $Method, $Headers, $JsonBody, $TimeoutSec)
			$script:writeCalls += "$Method $Uri"
			# if/else: GENAU EIN Objekt pro Aufruf (bare expression + return wuerde
			# zwei Objekte emittieren und StatusCode-Binding als Object[] sprengen)
			if ($Uri -match 'denylist' -and $Method -eq 'POST' -and $JsonBody -match 'badwebsite') {
				return [PSCustomObject]@{ StatusCode = 200; Content = '{"errors":[{"code":"invalid","detail":"badwebsite is not a valid domain"}]}'; Headers = $null; TransportError = $null }
			}
			return [PSCustomObject]@{ StatusCode = 200; Content = '{"data":{"id":"ok"}}'; Headers = $null; TransportError = $null }
		}
	}

	It 'erzeugt bei -WhatIf garantiert keinen HTTP-Call' {
		$res = Add-NextDnsDenylistEntry -Domains 'whatif.example.com' -WhatIf
		$script:writeCalls.Count | Should -Be 0
		$res.Ok | Should -BeFalse   # WhatIf-Abbruch ist kein Erfolg
	}

	It 'wertet 200 OK + errors[] je Domain als Fehler aus' {
		$res = Add-NextDnsDenylistEntry -Domains 'badwebsite'
		$res.Ok | Should -BeFalse
		$res.Error | Should -Match 'not a valid domain'
		($script:writeCalls | Where-Object { $_ -match 'POST .*/denylist' }).Count | Should -Be 1
	}

	It 'nutzt DELETE am Child-Endpoint zum Entfernen' {
		$res = Remove-NextDnsDenylistEntry -Domains 'good.example.com'
		$res.Ok | Should -BeTrue
		$script:writeCalls[-1] | Should -Match 'DELETE .*/denylist/good\.example\.com$'
	}

	It 'liefert Batch-Mischresultat als einzelne Ergebnis-Objekte' {
		$res = @(Add-NextDnsDenylistEntry -Domains @('good.example.com', 'badwebsite', ''))
		$res.Count | Should -Be 3
		@($res | Where-Object { $_.Ok }).Count | Should -Be 1
		@($res | Where-Object { -not $_.Ok }).Count | Should -Be 2
	}

	It 'validiert Settings-Sektionen (ValidateSet)' {
		{ Set-NextDnsSettings -Section 'hacker/path' -Body @{} -WhatIf } | Should -Throw
		$r = Set-NextDnsSettings -Section 'settings/blockPage' -Body @{ enabled = $true }
		$r.Ok | Should -BeTrue
		($script:writeCalls | Where-Object { $_ -match 'PATCH .*/settings/blockPage' }).Count | Should -Be 1
	}

	It 'deklariert Clear-NextDnsLogs mit ConfirmImpact=High' {
		$cmd = Get-Command Clear-NextDnsLogs
		$attr = $cmd.ScriptBlock.Attributes |
			Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] } |
			Select-Object -First 1
		$attr.ConfirmImpact | Should -Be 'High'
		$attr.SupportsShouldProcess | Should -BeTrue
		$r = Clear-NextDnsLogs -Confirm:$false
		$r.Ok | Should -BeTrue
		($script:writeCalls | Where-Object { $_ -match 'DELETE .*/logs$' }).Count | Should -Be 1
	}
}

Describe 'Dispatch-Tabelle (Befund 8/9)' {
	It 'enthaelt 17 Actions mit eindeutigen Keys' {
		$table = Get-NextDnsMenuTable
		$table.Count | Should -Be 17
		$keys = @($table | ForEach-Object { $_.Key })
		($keys | Sort-Object -Unique).Count | Should -Be 17
	}

	It 'referenziert nur existierende Funktionen' {
		$table = Get-NextDnsMenuTable
		foreach ($entry in $table) {
			Get-Command $entry.Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
		}
	}

	It 'markiert schreibende Actions als write' {
		$table = Get-NextDnsMenuTable
		@($table | Where-Object { $_.Kind -eq 'write' }).Count | Should -BeGreaterOrEqual 5
	}
}

Describe 'Nerd-Font-Erkennung' {
	It 'initialisiert einen Icon-Modus' {
		Initialize-NextDnsIcons
		$info = Get-NextDnsFontInfo
		$info.Mode | Should -BeIn @('nerd', 'ascii')
	}

	It 'faellt ohne Font auf ASCII zurueck (Fail-Safe)' {
		Set-NextDnsIconMode -Mode 'ascii'
		$icons = Get-NextDnsIcons
		$icons.Mode | Should -Be 'ascii'
		$icons.Check | Should -Be 'OK'
	}
}

Describe 'Config' {
	It 'validiert Profil-ID-Format (6 alphanumerische Zeichen)' {
		{ Set-NextDnsProfileId -ProfileId 'ab12' } | Should -Throw
		{ Set-NextDnsProfileId -ProfileId 'ZZ9Z9Z' } | Should -Not -Throw
	}

	It 'erkennt unvollstaendige Konfiguration' {
		$cfg = Get-NextDnsConfig
		$oldKey = $cfg.ApiKey
		$oldProfile = $cfg.ProfileId
		$cfg.ApiKey = ''
		{ Assert-NextDnsConfigReady } | Should -Throw
		$cfg.ApiKey = $oldKey
		$cfg.ProfileId = $oldProfile
		{ Assert-NextDnsConfigReady } | Should -Not -Throw
	}
}

Describe 'HTTP-Request-Contract (Issue #65)' {
	# Seam-Hinweis: Der Delegate (Set-NextDnsHttpDelegate) springt VOR
	# Invoke-NextDnsHttpRequest ein und kann den ContentType des echten
	# Calls strukturell nicht sehen (Luecke, die #65 zunaechst versteckt
	# hielt). Deshalb hier der echte Pfad: Invoke-WebRequest wird gemockt.
	# Wichtig: Stale Delegates aus frueheren Describes zusaetzlich
	# zuruecksetzen, sonst werden diese Tests nie erreicht.
	BeforeAll {
		Set-NextDnsHttpDelegate -Delegate $null
	}

	It 'sendet Content-Type application/json, wenn ein JSON-Body mitgeht' {
		InModuleScope NextDnsManager {
			$script:SeenRequest = $null
			Mock Invoke-WebRequest {
				param($Uri, $Method, $Headers, $Body, $ContentType, $TimeoutSec, $ErrorAction)
				$script:SeenRequest = [PSCustomObject]@{ ContentType = $ContentType; Body = $Body; Method = $Method }
				[PSCustomObject]@{ StatusCode = 200; Content = '{"data":{"id":"ct"}}'; Headers = $null }
			}
			$r = Invoke-NextDnsApi -Method 'POST' -Endpoint '/profiles/abc123/denylist' -Body @{ id = 'contract-test.example'; active = $true }
			$r.Ok | Should -BeTrue
			$script:SeenRequest.Method | Should -Be 'POST'
			$script:SeenRequest.ContentType | Should -Be 'application/json'
			$script:SeenRequest.Body | Should -Match 'contract-test\.example'
		}
	}

	It 'sendet keinen Content-Type bei Body-losen Calls (GET)' {
		InModuleScope NextDnsManager {
			$script:SeenRequest = $null
			Mock Invoke-WebRequest {
				param($Uri, $Method, $Headers, $Body, $ContentType, $TimeoutSec, $ErrorAction)
				$script:SeenRequest = [PSCustomObject]@{ ContentType = $ContentType; Body = $Body; Method = $Method }
				[PSCustomObject]@{ StatusCode = 200; Content = '{"data":[]}'; Headers = $null }
			}
			$r = Invoke-NextDnsApi -Method 'GET' -Endpoint '/profiles/abc123/denylist'
			$r.Ok | Should -BeTrue
			$script:SeenRequest.Method | Should -Be 'GET'
			$script:SeenRequest.ContentType | Should -BeNullOrEmpty
			$script:SeenRequest.Body | Should -BeNullOrEmpty
		}
	}
}
