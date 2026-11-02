# Starts Enemy Within (Long War installed) windowed and waits until its main menu is up (both games are never up at
# once: XCOM 2 is stopped first). Run in the desktop session (tools/test/on.sh). As a player does: through Steam
# (steam://rungameid/200510), whose XCOM launcher then starts Enemy Within (-FROMLAUNCHER) when its button is clicked.
# Started by itself, XComEW.exe has Steam restart the app's default, Enemy Unknown's XComGame.exe.
param([int]$TimeoutSeconds = 240)
. (Join-Path $PSScriptRoot 'ew.ps1')
Get-Process XCom2, XComEW, XComGame, XCOMLauncher -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep 2
# Windowed, at XCOM 2's test size (the game's own settings file in Documents).
$ini = "$EWDocs\Config\XComEngine.ini"
if (Test-Path $ini) {
  (Get-Content $ini) -replace '^Fullscreen=True', 'Fullscreen=False' -replace '^ResX=\d+', 'ResX=1600' -replace '^ResY=\d+', 'ResY=900' | Set-Content $ini
}
if (Test-Path $EWLog) { Remove-Item $EWLog -Force -ErrorAction SilentlyContinue }
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class LwxWin {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
}
'@
Start-Process 'steam://rungameid/200510'
$t0 = Get-Date
do { Start-Sleep 2; $launcher = Get-Process XCOMLauncher -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } } until ($launcher -or ((Get-Date) - $t0).TotalSeconds -gt 60)
if (-not $launcher) { "no XCOM launcher after 60 s"; exit 1 }
Start-Sleep 2
$r = New-Object LwxWin+RECT
[LwxWin]::GetWindowRect($launcher[0].MainWindowHandle, [ref]$r) | Out-Null
# The launcher's Enemy Within button: the upper of its two, 30 % across and 32 % down its window.
$x = $r.Left + [int](($r.Right - $r.Left) * 0.30)
$y = $r.Top + [int](($r.Bottom - $r.Top) * 0.32)
& (Join-Path $PSScriptRoot '..\test\click-screen.ps1') $x $y
do {
  Start-Sleep 3
  $ready = (Test-Path $EWLog) -and (Select-String -Path $EWLog -Pattern 'UIFinalShell:OnInit|UIShell:OnInit|LoadMap: XComShell' -Quiet)
} until ($ready -or ((Get-Date) - $t0).TotalSeconds -gt $TimeoutSeconds)
Start-Sleep 8
$p = Get-Process XComEW -ErrorAction SilentlyContinue
if ($ready -and $p) { "EW main menu up after {0:N0} s ({1})" -f ((Get-Date) - $t0).TotalSeconds, $p.Path } else { "no EW main menu after $TimeoutSeconds s (XComEW running: $([bool]$p))"; exit 1 }
