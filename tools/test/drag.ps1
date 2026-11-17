# A left-button drag from one point of the screen to another, in the screenshot's pixels (the SDK editor's wires).
param([Parameter(Mandatory)][int]$X1, [Parameter(Mandatory)][int]$Y1, [Parameter(Mandatory)][int]$X2, [Parameter(Mandatory)][int]$Y2)
Add-Type -AssemblyName System.Windows.Forms
Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern void mouse_event(uint f, uint x, uint y, uint d, IntPtr e);' -Name M -Namespace W4
$sb = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
function To([int]$x, [int]$y) { [W4.M]::mouse_event(0x8001, [uint32]([int]($x * 65535 / ($sb.Width - 1))), [uint32]([int]($y * 65535 / ($sb.Height - 1))), 0, [IntPtr]::Zero) }
To $X1 $Y1; Start-Sleep -Milliseconds 150
[W4.M]::mouse_event(0x0002, 0, 0, 0, [IntPtr]::Zero); Start-Sleep -Milliseconds 150
foreach ($k in 1..12) { To ([int]($X1 + ($X2 - $X1) * $k / 12)) ([int]($Y1 + ($Y2 - $Y1) * $k / 12)); Start-Sleep -Milliseconds 40 }
Start-Sleep -Milliseconds 150
[W4.M]::mouse_event(0x0004, 0, 0, 0, [IntPtr]::Zero); Start-Sleep -Milliseconds 300
