# Sets the primary display's resolution and its scaling to 100 % (for the test machine:
# the editor is not DPI-aware, and smaller screenshots are quicker to take and to read).
param([int]$Width = 1920, [int]$Height = 1080)
Add-Type @"
using System; using System.Runtime.InteropServices;
[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
public struct DEVMODE {
  [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmDeviceName;
  public short dmSpecVersion, dmDriverVersion, dmSize, dmDriverExtra; public int dmFields;
  public int dmPositionX, dmPositionY, dmDisplayOrientation, dmDisplayFixedOutput;
  public short dmColor, dmDuplex, dmYResolution, dmTTOption, dmCollate;
  [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmFormName;
  public short dmLogPixels; public int dmBitsPerPel, dmPelsWidth, dmPelsHeight, dmDisplayFlags, dmDisplayFrequency;
  public int dmICMMethod, dmICMIntent, dmMediaType, dmDitherType, dmReserved1, dmReserved2, dmPanningWidth, dmPanningHeight;
}
public class D {
  [DllImport("user32.dll")] public static extern bool EnumDisplaySettings(string dev, int mode, ref DEVMODE dm);
  [DllImport("user32.dll")] public static extern int ChangeDisplaySettings(ref DEVMODE dm, int flags);
  [DllImport("user32.dll")] public static extern bool SystemParametersInfo(uint a, int p, IntPtr v, uint w);
}
"@
$dm = New-Object DEVMODE
$dm.dmSize = [Runtime.InteropServices.Marshal]::SizeOf($dm)
[D]::EnumDisplaySettings($null, -1, [ref]$dm) | Out-Null
$dm.dmPelsWidth = $Width; $dm.dmPelsHeight = $Height; $dm.dmFields = 0x80000 -bor 0x100000
$r = [D]::ChangeDisplaySettings([ref]$dm, 1)
"resolution: {0}x{1} ({2})" -f $Width, $Height, $(if ($r -eq 0) { 'set' } else { "failed $r" })
# Scaling: the relative step from the recommended one, as Settings sets it live
# (SPI_SETLOGICALDPIOVERRIDE). At 1920x1080 the recommended is 100 %.
[D]::SystemParametersInfo(0x9F, 0, [IntPtr]::Zero, 1) | Out-Null
"scaling: the recommended (100 % at this size)"
