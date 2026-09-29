# npm-Cleanup: verifiziert den npm-Cache (Garbage Collection stale Eintraege) und
# entfernt nur sicher wegwerfbare Dinge: npm-eigene Logs und Cache-TMP-Dateien.
# Niemals: global installierte Pakete, node_modules in Projekten, package-lock.json.
$ErrorActionPreference = 'Continue'

$maintDir = "$env:LOCALAPPDATA\Maintenance"
$log      = Join-Path $maintDir 'npm-cleanup.log'
$keepRotated = 5
$npmCache = "$env:LOCALAPPDATA\npm-cache"
$npmCmd   = "$env:ProgramFiles\nodejs\npm.cmd"

function Write-Log($m) {
    Add-Content -Path $log -Value ("[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m)
}
function Rotate-Log {
    if ((Test-Path $log) -and ((Get-Item $log -Force).Length -gt 5MB)) {
        Move-Item $log ("$log.{0}" -f (Get-Date -Format 'yyyyMMdd-HHmmss')) -Force
        Get-ChildItem $maintDir -Filter 'npm-cleanup.log.*' -File -EA SilentlyContinue |
            Sort-Object LastWriteTime -Descending | Select-Object -Skip $keepRotated |
            Remove-Item -Force -EA SilentlyContinue
    }
}
function Get-DirSizeMB($p) {
    if (-not (Test-Path $p)) { return 0 }
    $s = (Get-ChildItem $p -Recurse -Force -EA SilentlyContinue | Measure-Object Length -Sum).Sum
    if ($null -eq $s) { return 0 }
    return [math]::Round($s / 1MB, 1)
}

Write-Log ("=== npm cache verify (vorher: {0} MB) ===" -f (Get-DirSizeMB $npmCache))
if (Test-Path $npmCmd) {
    & $npmCmd cache verify 2>&1 | ForEach-Object { Write-Log ("  npm: $_") }
} else {
    Write-Log "  npm.cmd nicht gefunden - uebersprungen"
}
Write-Log ("Cache nach verify: {0} MB" -f (Get-DirSizeMB $npmCache))

$freed = 0
# 1) npm-eigene Debug-Logs (> 14 Tage)
$logsDir = Join-Path $npmCache '_logs'
if (Test-Path $logsDir) {
    $cutoff = (Get-Date).AddDays(-14)
    Get-ChildItem $logsDir -Filter '*.log' -File -EA SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt $cutoff } |
        ForEach-Object { $freed += $_.Length; Write-Log ("Deleted npm-log: " + $_.Name); Remove-Item $_.FullName -Force -EA SilentlyContinue }
}
# 2) Cache-TMP (> 7 Tage)
$tmpDir = Join-Path $npmCache '_cacache\tmp'
if (Test-Path $tmpDir) {
    $cutoff2 = (Get-Date).AddDays(-7)
    Get-ChildItem $tmpDir -Recurse -File -EA SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt $cutoff2 } |
        ForEach-Object { $freed += $_.Length; Remove-Item $_.FullName -Force -EA SilentlyContinue }
    Write-Log "Cache-TMP geprueft (Alter > 7 Tage)"
}
Write-Log ("Fertig: {0:N1} KB durch Log/TMP-Loeschung freigegeben" -f ($freed / 1KB))
Rotate-Log
