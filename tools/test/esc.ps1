. (Join-Path $PSScriptRoot 'game.ps1')
Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern void keybd_event(byte v, byte s, uint f, IntPtr e);' -Name K -Namespace W
Focus-Game | Out-Null
[W.K]::keybd_event(0x1B, 0, 0, [IntPtr]::Zero); Start-Sleep -Milliseconds 80; [W.K]::keybd_event(0x1B, 0, 2, [IntPtr]::Zero)
