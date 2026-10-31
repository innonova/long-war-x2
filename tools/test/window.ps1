# Brings a window to the front by its title (a regular expression), maximized: for the editor and its dialogs.
param([Parameter(Mandatory)][string]$Title, [switch]$NoMaximize)
Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class WW {
  public delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc f, IntPtr l);
  [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
}
"@
$found = [IntPtr]::Zero
[WW]::EnumWindows({ param($h, $l) $sb = New-Object Text.StringBuilder 256; [WW]::GetWindowText($h, $sb, 256) | Out-Null; if ([WW]::IsWindowVisible($h) -and $sb.ToString() -match $Title) { $script:found = $h; return $false }; return $true }, [IntPtr]::Zero) | Out-Null
if ($found -eq [IntPtr]::Zero) { exit 1 }
[WW]::ShowWindow($found, $(if ($NoMaximize) { 9 } else { 3 })) | Out-Null
[WW]::SetForegroundWindow($found) | Out-Null
