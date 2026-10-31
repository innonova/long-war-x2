# The mouse wheel at a point of the screen: positive is away from the user (zooming in, in most viewers).
param([Parameter(Mandatory)][int]$X, [Parameter(Mandatory)][int]$Y, [int]$Clicks = 3)
Add-Type -AssemblyName System.Windows.Forms
Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern void mouse_event(uint f, uint x, uint y, int d, IntPtr e);' -Name M -Namespace W2
$sb = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
[W2.M]::mouse_event(0x8001, [uint32]($X * 65535 / ($sb.Width - 1)), [uint32]($Y * 65535 / ($sb.Height - 1)), 0, [IntPtr]::Zero)
Start-Sleep -Milliseconds 200
foreach ($i in 1..[Math]::Abs($Clicks)) { [W2.M]::mouse_event(0x0800, 0, 0, [Math]::Sign($Clicks) * 120, [IntPtr]::Zero); Start-Sleep -Milliseconds 80 }
