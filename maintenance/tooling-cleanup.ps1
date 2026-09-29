# Tooling-Cleanup: raeumt Logs/Temp-Dateien der Installationen Routed, synapse-mcp, claimidx auf.
# Niemals angefasst werden: Index-Datenbanken (index.db*, index.sqlite), Identitaeten
# (identity.json, config.json), Skill-Modell (model/), Adapter (adapters/), Queue (outbox).
$ErrorActionPreference = 'Continue'

$maintDir = "$env:LOCALAPPDATA\Maintenance"
$log      = Join-Path $maintDir 'tooling-cleanup.log'
$ageDays     = 14   # Loeschalter fuer *.log/*.tmp in den Zielordnern
$keepRotated = 5    # watch.log-Rotationen bleiben erhalten (identisch zum Watch-Wrapper)
$maxAgeDays  = 30

function Write-Log($m) {
    Add-Content -Path $log -Value ("[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m)
}
function Rotate-Log {
    if ((Test-Path $log) -and ((Get-Item $log -Force).Length -gt 5MB)) {
        Move-Item $log ("$log.{0}" -f (Get-Date -Format 'yyyyMMdd-HHmmss')) -Force
        Get-ChildItem $maintDir -Filter 'tooling-cleanup.log.*' -File -EA SilentlyContinue |
            Sort-Object LastWriteTime -Descending | Select-Object -Skip $keepRotated |
            Remove-Item -Force -EA SilentlyContinue
    }
}

$cutoff = (Get-Date).AddDays(-$ageDays)
$targets = @(
    @{ Dir = "$env:APPDATA\Routed\logs";           Pattern = '*.log' },
    @{ Dir = "$env:LOCALAPPDATA\Routed";           Pattern = 'watch.log.*' },
    @{ Dir = "$env:LOCALAPPDATA\Routed";           Pattern = '*.tmp' },
    @{ Dir = "$env:USERPROFILE\.synapse-mcp\logs"; Pattern = '*.log' }
)
# claimidx (~\.claimidx): alle Dateien dort sind Datenbank/Identitaet/Queue -> bewusst kein Ziel.

$freed = 0
foreach ($t in $targets) {
    if (-not (Test-Path $t.Dir)) { continue }
    $old = Get-ChildItem -Path $t.Dir -Filter $t.Pattern -File -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt $cutoff }
    foreach ($f in $old) {
        $freed += $f.Length
        Remove-Item $f.FullName -Force -ErrorAction SilentlyContinue
        Write-Log ("Deleted: {0} ({1:N0} KB)" -f $f.FullName, ($f.Length / 1KB))
    }
}
Write-Log ("Fertig: {0:N1} KB freigegeben (Alter > {1} Tage)" -f ($freed / 1KB), $ageDays)
Rotate-Log
