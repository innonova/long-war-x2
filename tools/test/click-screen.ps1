# A left click (or a double click) at a point of the screen, in the screenshot's pixels.
param([Parameter(Mandatory)][int]$X, [Parameter(Mandatory)][int]$Y, [switch]$Double, [switch]$Right)
Add-Type -AssemblyName System.Windows.Forms
Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern void mouse_event(uint f, uint x, uint y, uint d, IntPtr e);' -Name M -Namespace W
$sb = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
foreach ($k in 1..4) {
  $mx = [int](($X - 8 + 2 * $k) * 65535 / ($sb.Width - 1)); $my = [int](($Y - 4 + $k) * 65535 / ($sb.Height - 1))
  [W.M]::mouse_event(0x8001, [uint32]$mx, [uint32]$my, 0, [IntPtr]::Zero); Start-Sleep -Milliseconds 40
}
Start-Sleep -Milliseconds 200
$down, $up = if ($Right) { 0x0008, 0x0010 } else { 0x0002, 0x0004 }
foreach ($i in 1..$(if ($Double) { 2 } else { 1 })) {
  [W.M]::mouse_event($down, 0, 0, 0, [IntPtr]::Zero); Start-Sleep -Milliseconds 60; [W.M]::mouse_event($up, 0, 0, 0, [IntPtr]::Zero); Start-Sleep -Milliseconds 90
}
Start-Sleep -Milliseconds 300
