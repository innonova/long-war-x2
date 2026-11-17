# The game's window, in its own client pixels (1600 x 900 in both games' test setups), for the comparison
# captures: a screenshot of the client area only, or a click or hover at a client point. Enemy Within or
# XCOM 2, whichever runs. Run in the desktop session (tools/test/on.sh).
#   win.ps1 shot C:\Users\aekms\cmp.png
#   win.ps1 click 640 28        win.ps1 hover 640 28        win.ps1 rclick 640 28
param([Parameter(Mandatory)][ValidateSet('shot', 'click', 'hover', 'rclick', 'rect')][string]$Do, [string]$A, [int]$B)
$Path = $A; $X = if ($Do -ne 'shot' -and $A) { [int]$A } else { 0 }; $Y = $B
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class LwxCmp {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
  [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }
  [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint x, uint y, uint d, IntPtr e);
}
'@
$p = Get-Process XComEW, XCom2 -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
if (-not $p) { 'no game window'; exit 1 }
$h = $p.MainWindowHandle
$r = New-Object LwxCmp+RECT; [LwxCmp]::GetClientRect($h, [ref]$r) | Out-Null
$o = New-Object LwxCmp+POINT; [LwxCmp]::ClientToScreen($h, [ref]$o) | Out-Null
$w = $r.Right; $hh = $r.Bottom
switch ($Do) {
  'rect' { "{0} client {1}x{2} at {3},{4}" -f $p.ProcessName, $w, $hh, $o.X, $o.Y }
  'shot' {
    $i = New-Object System.Drawing.Bitmap $w, $hh
    [System.Drawing.Graphics]::FromImage($i).CopyFromScreen($o.X, $o.Y, 0, 0, (New-Object System.Drawing.Size $w, $hh))
    $i.Save($Path); "{0} {1}x{2}" -f $Path, $w, $hh
  }
  default {
    $sb = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $sx = $o.X + $X; $sy = $o.Y + $Y
    # A few small steps onto the point: both games' Flash only sees a hover from motion.
    foreach ($k in 1..4) {
      $mx = [int](($sx - 8 + 2 * $k) * 65535 / ($sb.Width - 1)); $my = [int](($sy - 4 + $k) * 65535 / ($sb.Height - 1))
      [LwxCmp]::mouse_event(0x8001, [uint32]$mx, [uint32]$my, 0, [IntPtr]::Zero); Start-Sleep -Milliseconds 40
    }
    Start-Sleep -Milliseconds 200
    if ($Do -eq 'hover') { return }
    $down, $up = if ($Do -eq 'rclick') { 0x0008, 0x0010 } else { 0x0002, 0x0004 }
    [LwxCmp]::mouse_event($down, 0, 0, 0, [IntPtr]::Zero); Start-Sleep -Milliseconds 60
    [LwxCmp]::mouse_event($up, 0, 0, 0, [IntPtr]::Zero); Start-Sleep -Milliseconds 300
  }
}
