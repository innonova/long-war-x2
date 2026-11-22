# Records the game window to a video for a while, in the background (ffmpeg's gdigrab, installed by winget: Gyan.FFmpeg),
# so transitions and timing can be looked at, not just stills (features/e2e-tests.md). Returns at once.
#   tools\test\record.ps1 C:\Users\aekms\clip.mp4 8
param([Parameter(Mandatory)][string]$Path, [double]$Seconds = 8, [int]$Fps = 20)
. (Join-Path $PSScriptRoot 'game.ps1')
$ff = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter ffmpeg.exe -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $ff) { "ERR no ffmpeg (winget install Gyan.FFmpeg)"; exit 1 }
$h = Get-GameWindow
if (-not $h) { "ERR no game window"; exit 1 }
$r = New-Object RECT; [GW]::GetClientRect($h, [ref]$r) | Out-Null
$o = New-Object POINT; [GW]::ClientToScreen($h, [ref]$o) | Out-Null
$w = ($r.R - $r.L) - (($r.R - $r.L) % 2); $hh = ($r.B - $r.T) - (($r.B - $r.T) % 2)
Remove-Item $Path -ErrorAction SilentlyContinue
$args = "-hide_banner -loglevel error -y -f gdigrab -framerate $Fps -offset_x $($o.X) -offset_y $($o.Y) -video_size ${w}x$hh -i desktop -t $Seconds -c:v libx264 -preset ultrafast -pix_fmt yuv420p `"$Path`""
Start-Process -FilePath $ff.FullName -ArgumentList $args -WindowStyle Hidden | Out-Null
"recording $Path for $Seconds s at $Fps fps"
