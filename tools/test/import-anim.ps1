# In the open AnimSet editor: File > Import FBX Animation of one file, through to done.
# Prints what happened: "imported <name>", or the window that stood in the way.
param([Parameter(Mandatory)][string]$Path)
$here = $PSScriptRoot
& "$here\window.ps1" '^Unreal AnimSet Editor' | Out-Null
Start-Sleep -Milliseconds 500
& "$here\click-screen.ps1" 16 33
Start-Sleep -Milliseconds 700
& "$here\click-screen.ps1" 100 130
Start-Sleep 2
& "$here\window.ps1" '^Import AnimSet' -NoMaximize | Out-Null
& "$here\click-screen.ps1" 460 515
& "$here\type.ps1" $Path -Literal
& "$here\type.ps1" '{ENTER}'
# The FBX warning, then the import itself: checked every second, up to a minute.
foreach ($i in 1..60) {
  Start-Sleep 1
  & "$here\windows.ps1"
  $w = Get-Content "$env:USERPROFILE\lwx2-windows.txt"
  if ($w -match 'Warning_IncompatibleFBX') { & "$here\window.ps1" 'Warning_IncompatibleFBX' -NoMaximize | Out-Null; & "$here\type.ps1" '{ENTER}'; continue }
  if ($w -contains 'Message') { "a Message window: stopped (see the screen)"; exit 1 }
  if (-not ($w -match '^Please Wait')) { "imported " + [IO.Path]::GetFileNameWithoutExtension($Path); exit 0 }
}
"still importing after a minute"; exit 1
