# Routed Watch Wrapper: startet den Skill-Watcher, schreibt zeilenweise in watch.log
# und rotiert/grenz die Logdatei ein, damit der Speicherverbrauch begrenzt bleibt.
$ErrorActionPreference = 'Continue'

$logDir = "$env:LOCALAPPDATA\Routed"
$log    = Join-Path $logDir 'watch.log'
$node   = "$env:ProgramFiles\nodejs\node.exe"
$routed = "$env:LOCALAPPDATA\Programs\Routed\packages\cli\bin\routed.js"
$maxBytes    = 10MB   # Schwelle: ab dieser Groesse rotieren
$keepRotated = 5      # so viele rotierte Dateien bleiben erhalten
$maxAgeDays  = 30     # rotierte Dateien aelter als X Tage werden geloescht

New-Item -ItemType Directory -Force -Path $logDir | Out-Null

function Invoke-Rotation {
    if (-not (Test-Path $log)) { return }
    $item = Get-Item $log -Force
    if ($item.Length -gt $maxBytes) {
        $stamp  = Get-Date -Format 'yyyyMMdd-HHmmss'
        $rotated = "$log.$stamp"
        Move-Item -Path $log -Destination $rotated -Force
        Add-Content -Path $log -Value ("[{0}] Log rotiert: {1:N1} MB -> {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), ($item.Length / 1MB), (Split-Path $rotated -Leaf))
        $cutoff = (Get-Date).AddDays(-$maxAgeDays)
        Get-ChildItem -Path $logDir -Filter 'watch.log.*' -File -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -lt $cutoff } |
            Remove-Item -Force -ErrorAction SilentlyContinue
        Get-ChildItem -Path $logDir -Filter 'watch.log.*' -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -Skip $keepRotated |
            Remove-Item -Force -ErrorAction SilentlyContinue
    }
}

Invoke-Rotation

$inner = ' "' + $node + '" "' + $routed + '" watch --quiet 2>&1 '
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName               = "$env:ComSpec"
$psi.Arguments              = '/d /s /c "' + $inner + '"'
$psi.UseShellExecute        = $false
$psi.RedirectStandardOutput = $true
$psi.CreateNoWindow         = $true

Add-Content -Path $log -Value ("[{0}] Watcher gestartet (PID {1}, Schwelle {2} MB, Behalten {3} Rotationen)" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $PID, ($maxBytes / 1MB), $keepRotated)

$p = [System.Diagnostics.Process]::Start($psi)
try {
    while ($null -ne ($line = $p.StandardOutput.ReadLine())) {
        Invoke-Rotation
        Add-Content -Path $log -Value $line
    }
} finally {
    if (-not $p.HasExited) { $p.Kill() }
}
