# The mod's build (X2ModBuildCommon, .scripts/X2ModBuildCommon): from ModBuddy,
# or by hand on the test machine:
#   pwsh .scripts\build.ps1 -srcDirectory . -sdkPath "<SDK>" -gamePath "<game>\XCom2-WarOfTheChosen" -config default
Param(
    [string] $srcDirectory,
    [string] $sdkPath,
    [string] $gamePath,
    [string] $config
)

$ScriptDirectory = Split-Path $MyInvocation.MyCommand.Path
$common = Join-Path -Path $ScriptDirectory "X2ModBuildCommon\build_common.ps1"
Write-Host "Sourcing $common"
. ($common)

$builder = [BuildProject]::new("LongWarX2", $srcDirectory, $sdkPath, $gamePath)

switch ($config)
{
    "debug" { $builder.EnableDebug() }
    "default" { }
    "" { ThrowFailure "Missing build configuration" }
    default { ThrowFailure "Unknown build configuration $config" }
}

$builder.InvokeBuild()
