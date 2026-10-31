# The visible windows' titles: what is open on the desktop.
Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class WL {
  public delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc f, IntPtr l);
  [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
}
"@
$titles = New-Object Collections.Generic.List[string]
[WL]::EnumWindows({ param($h, $l) $sb = New-Object Text.StringBuilder 256; [WL]::GetWindowText($h, $sb, 256) | Out-Null; if ([WL]::IsWindowVisible($h) -and $sb.Length) { $titles.Add($sb.ToString()) }; return $true }, [IntPtr]::Zero) | Out-Null
$titles | Set-Content "$env:USERPROFILE\lwx2-windows.txt"
