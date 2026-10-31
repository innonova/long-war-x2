# Shared by the scripts: the game, its config and log, and its window.
$GameDir = "C:\Program Files (x86)\Steam\steamapps\common\XCOM 2\XCom2-WarOfTheChosen"
$UserDir = "$env:USERPROFILE\Documents\My Games\XCOM2 War of the Chosen\XComGame"
$ModOptions = "$UserDir\Config\XComModOptions.ini"
$GameLog = "$UserDir\Logs\Launch.log"
Add-Type @"
using System; using System.Runtime.InteropServices;
public struct RECT { public int L, T, R, B; }
public struct POINT { public int X, Y; }
public class GW {
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
  [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr a, int x, int y, int cx, int cy, uint f);
  [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint x, uint y, uint d, IntPtr e);
}
"@
function Get-GameWindow { (Get-Process XCom2 -ErrorAction SilentlyContinue | Select-Object -First 1).MainWindowHandle }
function Focus-Game {
  $h = Get-GameWindow
  if (-not $h) { return $null }
  [GW]::ShowWindow($h, 9) | Out-Null
  [GW]::SetWindowPos($h, [IntPtr]::Zero, 0, 0, 0, 0, 0x0001 -bor 0x0040) | Out-Null
  [GW]::SetForegroundWindow($h) | Out-Null
  Start-Sleep -Milliseconds 400
  return $h
}
