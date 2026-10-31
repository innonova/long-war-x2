# A left click at a point of the game's UI, given in its 1920x1080 coordinates.
param([Parameter(Mandatory)][double]$X, [Parameter(Mandatory)][double]$Y)
. (Join-Path $PSScriptRoot 'game.ps1')
$h = Focus-Game
if (-not $h) { exit 1 }
$r = New-Object RECT; [GW]::GetClientRect($h, [ref]$r) | Out-Null
$o = New-Object POINT; [GW]::ClientToScreen($h, [ref]$o) | Out-Null
$scale = [Math]::Min(($r.R - $r.L) / 1920.0, ($r.B - $r.T) / 1080.0)
[GW]::SetCursorPos([int]($o.X + $X * $scale), [int]($o.Y + $Y * $scale)) | Out-Null
Start-Sleep -Milliseconds 250
[GW]::mouse_event(0x0002, 0, 0, 0, [IntPtr]::Zero); Start-Sleep -Milliseconds 80; [GW]::mouse_event(0x0004, 0, 0, 0, [IntPtr]::Zero)
Start-Sleep -Milliseconds 300
