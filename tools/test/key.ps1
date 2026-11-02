# Holds a key down in the focused window for a while (games read held keys, not typed text):
#   key.ps1 W 1500        # W for 1.5 s
# Sent as a scan code, which the game's raw input reads.
param([Parameter(Mandatory)][string]$Key, [int]$Ms = 300)
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class LwxKey {
  [DllImport("user32.dll")] public static extern uint MapVirtualKey(uint code, uint type);
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
}
'@
Add-Type -AssemblyName System.Windows.Forms
# A digit is the digit's key (D6), not the virtual key of that number (6 is the mouse's XButton2, which turned XCOM 2's
# world black under its HUD).
if ($Key -match '^\d$') { $Key = "D$Key" }
$vk = [uint32][System.Windows.Forms.Keys]$Key
$scan = [byte][LwxKey]::MapVirtualKey($vk, 0)
# Arrows and the keys above them are "extended" keys: without the flag their scan codes are the numpad's (Down was
# read as numpad 2).
$ext = if (@('Up', 'Down', 'Left', 'Right', 'Home', 'End', 'PageUp', 'PageDown', 'Insert', 'Delete') -contains $Key) { 0x1 } else { 0 }
[LwxKey]::keybd_event([byte]$vk, $scan, 0x8 -bor $ext, [UIntPtr]::Zero)        # KEYEVENTF_SCANCODE
Start-Sleep -Milliseconds $Ms
[LwxKey]::keybd_event([byte]$vk, $scan, 0x8 -bor 0x2 -bor $ext, [UIntPtr]::Zero) # and KEYEVENTF_KEYUP
