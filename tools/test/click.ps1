# A left click at a point of the game's UI, given in its 1920x1080 coordinates.
param([Parameter(Mandatory)][double]$X, [Parameter(Mandatory)][double]$Y)
. (Join-Path $PSScriptRoot 'game.ps1')
$h = Focus-Game
if (-not $h) { exit 1 }
$r = New-Object RECT; [GW]::GetClientRect($h, [ref]$r) | Out-Null
$o = New-Object POINT; [GW]::ClientToScreen($h, [ref]$o) | Out-Null
$scale = [Math]::Min(($r.R - $r.L) / 1920.0, ($r.B - $r.T) / 1080.0)
$tx = [int]($o.X + $X * $scale); $ty = [int]($o.Y + $Y * $scale)
# Real movement (absolute, in 0..65535 of the screen), a few steps, so the game sees the
# pointer arrive and hover before the press: setting the cursor's position is not enough.
Add-Type -AssemblyName System.Windows.Forms
$sb = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
foreach ($k in 1..6) {
  $mx = [int](($tx - 30 + 5 * $k) * 65535 / ($sb.Width - 1)); $my = [int](($ty - 12 + 2 * $k) * 65535 / ($sb.Height - 1))
  [GW]::mouse_event(0x8001, [uint32]$mx, [uint32]$my, 0, [IntPtr]::Zero)
  Start-Sleep -Milliseconds 60
}
Start-Sleep -Milliseconds 300
[GW]::mouse_event(0x0002, 0, 0, 0, [IntPtr]::Zero); Start-Sleep -Milliseconds 100; [GW]::mouse_event(0x0004, 0, 0, 0, [IntPtr]::Zero)
Start-Sleep -Milliseconds 300
