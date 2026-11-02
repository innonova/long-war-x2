# Builds the mod into the game (X2ModBuildCommon under Windows PowerShell 5.1, as ModBuddy runs it)
# and prints the compiler's errors and warnings.
$repo = Split-Path (Split-Path $PSScriptRoot)
$sdk = "C:\Program Files (x86)\Steam\steamapps\common\XCOM 2 War of the Chosen SDK"
$game = "C:\Program Files (x86)\Steam\steamapps\common\XCOM 2\XCom2-WarOfTheChosen"
$log = Join-Path $repo 'BuildCache\build.log'
New-Item -ItemType Directory -Force (Split-Path $log) | Out-Null
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$repo\.scripts\build.ps1" -srcDirectory $repo -sdkPath $sdk -gamePath $game -config default *> $log
$code = $LASTEXITCODE
# Enemy Within's texture caches, under the names converted EW packages use (tools/convert/README.md),
# linked into the built mod's Content: the build replaces that folder each time. Hard links, no copies.
$ew = "C:\Program Files (x86)\Steam\steamapps\common\XCom-Enemy-Unknown\XEW\XComGame\CookedPCConsole"
if (Test-Path $ew) {
  foreach ($content in @("$game\XComGame\Mods\LongWarX2\Content", "$sdk\XComGame\Mods\LongWarX2\Content")) {
    if (-not (Test-Path $content)) { continue }
    foreach ($pair in @(@('CharTextures', 'EWCharTextrs'), @('Textures', 'EWTextrs'), @('Lighting', 'EWLightg'), @('Textures_startup', 'EWTextrs_startup'))) {
      $link = Join-Path $content "$($pair[1]).tfc"
      $target = Join-Path $ew "$($pair[0]).tfc"
      if ((Test-Path $target) -and -not (Test-Path $link)) { New-Item -ItemType HardLink -Path $link -Target $target | Out-Null }
    }
  }
}
# Converted Enemy Within packages (maps, screens, units: tools/convert) live outside the mod's Content, in
# BuildCache\ewcontent: the build processes every package in Content, and 83 maps (18 GB) made it take
# far too long. They are linked into the built mod's Content after the build instead. Hard links, no copies.
$converted = Join-Path $repo 'BuildCache\ewcontent'
if (Test-Path $converted) {
  foreach ($content in @("$game\XComGame\Mods\LongWarX2\Content", "$sdk\XComGame\Mods\LongWarX2\Content")) {
    if (-not (Test-Path (Split-Path $content))) { continue }
    New-Item -ItemType Directory -Force $content | Out-Null
    foreach ($f in Get-ChildItem $converted | Where-Object { $_.Extension -in '.upk', '.umap' }) {
      $link = Join-Path $content $f.Name
      if (Test-Path $link) { Remove-Item $link }
      New-Item -ItemType HardLink -Path $link -Target $f.FullName | Out-Null
    }
  }
  # Each EW map's own plot (tools/convert/ew-plot.ts: LWX2_<map>.umap) listed as a plot of Long War X2's type.
  $plots = Get-ChildItem $converted -Filter 'LWX2_*.umap' | Where-Object { $_.BaseName -ne 'LWX2_EWPlotTemplate' }
  if ($plots) {
    $ini = "$game\XComGame\Mods\LongWarX2\Config\XComPlots.ini"
    Add-Content $ini ('; The plots of the Enemy Within maps converted on this machine (tools/test/build.ps1).')
    foreach ($p in $plots) { Add-Content $ini ('+arrPlots=(MapName="' + $p.BaseName + '", strType="LWX2_EW", ExcludeFromStrategy=true, ValidBiomes[0]="Arid", ObjectiveTags[0]="LWX2_EW")') }
  }
}
# Long War X2's own maps (tools/maps: the template plot, the empty parcel) linked into the built mod's Content too.
foreach ($content in @("$game\XComGame\Mods\LongWarX2\Content", "$sdk\XComGame\Mods\LongWarX2\Content")) {
  if (-not (Test-Path (Split-Path $content))) { continue }
  New-Item -ItemType Directory -Force $content | Out-Null
  foreach ($f in Get-ChildItem (Join-Path $repo 'tools\maps') -Filter *.umap) {
    $link = Join-Path $content $f.Name
    if (Test-Path $link) { Remove-Item $link }
    New-Item -ItemType HardLink -Path $link -Target $f.FullName | Out-Null
  }
}
Select-String -Path $log -Pattern ': Error|: Warning|SUCCESS|Failed' | ForEach-Object { $_.Line.Replace("$repo\", '') }
exit $code
