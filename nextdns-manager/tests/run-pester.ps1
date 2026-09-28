#Requires -Version 7.4
# run-pester.ps1 - permanenter Wrapper fuer den Pester-Lauf als Kind-Prozess.
#
# Warum ein Wrapper-File: test.ps1 started Pester in einem eigenen pwsh -
# als -Command-String wuerde das verschachtelte Quoting (Bash -> pwsh ->
# pwsh -Command -> Pester-Config) zur Fehlerquelle. Per -File gibt es kein
# Quoting-Spiel mehr. Pester 5 und 6 unterscheiden sich im Return-Vertrag
# (5: RunResult, 6: $null bei Exit=$false) - mit Run.Exit=$true und
# LASTEXITCODE ist der Lauf version-agnostisch.
#
# Exit-Codes: 0 = alle Tests gruen, != 0 = Fehlgeschlagen (Pester-Exit).

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Import-Module Pester -MinimumVersion 5.0.0 -ErrorAction Stop

$testsPath = Join-Path -Path $PSScriptRoot -ChildPath 'NextDnsManager.Tests.ps1'
$cfg = New-PesterConfiguration
$cfg.Run.Path = $testsPath
$cfg.Run.Exit = $true
$cfg.Output.Verbosity = 'Normal'
Invoke-Pester -Configuration $cfg
