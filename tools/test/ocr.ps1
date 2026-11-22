# The game window's text as Windows' own OCR reads it (-Gain brightens first) (Windows.Media.Ocr, no install): one line per word group, its
# box in the game's 1920x1080 UI coordinates (as click.ps1 takes them): "x y w h text". The E2E click tests find a
# menu item by its label this way, as a player does (features/e2e-tests.md).
#   tools\test\ocr.ps1 [-Scale 2]
param([double]$Scale = 2, [double]$Gain = 1, [switch]$Words, [switch]$Bands, [switch]$Invert, [string]$Region = '')
. (Join-Path $PSScriptRoot 'game.ps1')
Add-Type -AssemblyName System.Drawing, System.Runtime.WindowsRuntime
$null = [Windows.Media.Ocr.OcrEngine, Windows.Foundation, ContentType = WindowsRuntime]
$null = [Windows.Graphics.Imaging.SoftwareBitmap, Windows.Foundation, ContentType = WindowsRuntime]
$null = [Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime]
$asTask = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
function Await($op, [Type]$t) { $task = $asTask.MakeGenericMethod($t).Invoke($null, @($op)); $task.Wait(-1) | Out-Null; $task.Result }

# (Focused and put back in place first, as click.ps1 does: read where the window had drifted, the top of the screen was
# cut off and the room tabs went unread.)
$h = Focus-Game
if (-not $h) { "ERR no game window"; exit 1 }
$r = New-Object RECT; [GW]::GetClientRect($h, [ref]$r) | Out-Null
$o = New-Object POINT; [GW]::ClientToScreen($h, [ref]$o) | Out-Null
$cw = $r.R - $r.L; $ch = $r.B - $r.T
$ui = [Math]::Min($cw / 1920.0, $ch / 1080.0)
# The client area, enlarged (OCR reads the game's small UI text better at twice the size).
# (-Region "x y w h" in the 1920x1080 UI: only that part read, enlarged more (the main menu's small buttons along the
# bottom are read alone, not with the whole screen).)
$rx = 0; $ry = 0
if ($Region) {
  $p = $Region -split ' '
  $rx = [int]([double]$p[0] * $ui); $ry = [int]([double]$p[1] * $ui)
  $cw = [int]([double]$p[2] * $ui); $ch = [int]([double]$p[3] * $ui)
}
$bmp = New-Object System.Drawing.Bitmap $cw, $ch
[System.Drawing.Graphics]::FromImage($bmp).CopyFromScreen($o.X + $rx, $o.Y + $ry, 0, 0, (New-Object System.Drawing.Size $cw, $ch))
$big = New-Object System.Drawing.Bitmap ([int]($cw * $Scale)), ([int]($ch * $Scale))
$g = [System.Drawing.Graphics]::FromImage($big); $g.InterpolationMode = 'HighQualityBicubic'
# (-Gain: brightened, so dim labels (the room tabs not chosen) read too.)
$ia = New-Object System.Drawing.Imaging.ImageAttributes
if ($Gain -ne 1 -or $Invert) {
  # (-Invert: grey, inverted, dark text on light: Windows' OCR misses some light-on-dark rows, the room tabs among them.)
  $cm = New-Object System.Drawing.Imaging.ColorMatrix
  if ($Invert) {
    $v = -$Gain / 3
    $cm.Matrix00 = $v; $cm.Matrix01 = $v; $cm.Matrix02 = $v
    $cm.Matrix10 = $v; $cm.Matrix11 = $v; $cm.Matrix12 = $v
    $cm.Matrix20 = $v; $cm.Matrix21 = $v; $cm.Matrix22 = $v
    $cm.Matrix40 = 1; $cm.Matrix41 = 1; $cm.Matrix42 = 1
  } else { $cm.Matrix00 = $Gain; $cm.Matrix11 = $Gain; $cm.Matrix22 = $Gain }
  $ia.SetColorMatrix($cm)
}
$g.DrawImage($bmp, (New-Object System.Drawing.Rectangle 0, 0, $big.Width, $big.Height), 0, 0, $cw, $ch, [System.Drawing.GraphicsUnit]::Pixel, $ia)
$engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages()
function Read-Image($img) {
  $file = Join-Path $env:TEMP 'lwx2-ocr.png'
  $img.Save($file)
  $sf = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($file)) ([Windows.Storage.StorageFile])
  $stream = Await ($sf.OpenAsync([Windows.Storage.FileAccessMode]::Read)) ([Windows.Storage.Streams.IRandomAccessStream])
  $decoder = Await ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($stream)) ([Windows.Graphics.Imaging.BitmapDecoder])
  $sb = Await ($decoder.GetSoftwareBitmapAsync()) ([Windows.Graphics.Imaging.SoftwareBitmap])
  $out = Await ($engine.RecognizeAsync($sb)) ([Windows.Media.Ocr.OcrResult])
  $stream.Dispose()
  if ($env:LWX2_OCR_ANGLE) { [Console]::Error.WriteLine("TextAngle " + $out.TextAngle) }
  return $out
}
# (-Bands: read in overlapping horizontal bands as well: Windows' OCR misses a whole row of labels now and then (the room
# tabs over their bar), and reads it alone.)
$results = @()
if ($Bands) {
  $bh = [int]($big.Height / 5); $step = [int]($bh * 0.75)
  for ($y = 0; $y -lt $big.Height; $y += $step) {
    $hgt = [Math]::Min($bh, $big.Height - $y)
    if ($hgt -lt 20) { break }
    $band = $big.Clone((New-Object System.Drawing.Rectangle 0, $y, $big.Width, $hgt), $big.PixelFormat)
    $results += [pscustomobject]@{ R = (Read-Image $band); DY = $y }
  }
} else { $results += [pscustomobject]@{ R = (Read-Image $big); DY = 0 } }
$k = 1.0 / ($Scale * $ui)
# (-Words: each word on its own, "x y w h line# text": OCR joins neighbouring labels into one line now and then.)
if ($Words) {
  $li = 0
  foreach ($rr in $results) { foreach ($line in $rr.R.Lines) { foreach ($w in $line.Words) { $b = $w.BoundingRect; "{0} {1} {2} {3} {4} {5}" -f [int]($b.X * $k + $rx / $ui), [int](($b.Y + $rr.DY) * $k + $ry / $ui), [int]($b.Width * $k), [int]($b.Height * $k), $li, $w.Text }; $li++ } }
  return
}
foreach ($rr in $results) { foreach ($line in $rr.R.Lines) {
  $x0 = 1e9; $y0 = 1e9; $x1 = 0; $y1 = 0
  foreach ($w in $line.Words) { $b = $w.BoundingRect; $x0 = [Math]::Min($x0, $b.X); $y0 = [Math]::Min($y0, $b.Y); $x1 = [Math]::Max($x1, $b.X + $b.Width); $y1 = [Math]::Max($y1, $b.Y + $b.Height) }
  $k = 1.0 / ($Scale * $ui)
  "{0} {1} {2} {3} {4}" -f [int]($x0 * $k + $rx / $ui), [int](($y0 + $rr.DY) * $k + $ry / $ui), [int](($x1 - $x0) * $k), [int](($y1 - $y0) * $k), $line.Text
} }
