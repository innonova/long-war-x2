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
$vk = [uint32][System.Windows.Forms.Keys]$Key
$scan = [byte][LwxKey]::MapVirtualKey($vk, 0)
[LwxKey]::keybd_event([byte]$vk, $scan, 0x8, [UIntPtr]::Zero)        # KEYEVENTF_SCANCODE
Start-Sleep -Milliseconds $Ms
[LwxKey]::keybd_event([byte]$vk, $scan, 0x8 -bor 0x2, [UIntPtr]::Zero) # and KEYEVENTF_KEYUP
