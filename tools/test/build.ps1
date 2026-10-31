# Builds the mod into the game (X2ModBuildCommon under Windows PowerShell 5.1, as ModBuddy runs it)
# and prints the compiler's errors and warnings.
$repo = Split-Path (Split-Path $PSScriptRoot)
$sdk = "C:\Program Files (x86)\Steam\steamapps\common\XCOM 2 War of the Chosen SDK"
$game = "C:\Program Files (x86)\Steam\steamapps\common\XCOM 2\XCom2-WarOfTheChosen"
$log = Join-Path $repo 'BuildCache\build.log'
New-Item -ItemType Directory -Force (Split-Path $log) | Out-Null
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$repo\.scripts\build.ps1" -srcDirectory $repo -sdkPath $sdk -gamePath $game -config default *> $log
$code = $LASTEXITCODE
Select-String -Path $log -Pattern ': Error|: Warning|SUCCESS|Failed' | ForEach-Object { $_.Line.Replace("$repo\", '') }
exit $code
