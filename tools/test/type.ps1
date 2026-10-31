# Types text into the focused window (SendKeys; {ENTER}, {TAB} and the like as SendKeys has them).
param([Parameter(Mandatory)][string]$Text, [switch]$Literal)
Add-Type -AssemblyName System.Windows.Forms
$t = if ($Literal) { $Text -replace '([+^%~(){}\[\]])', '{$1}' } else { $Text }
[System.Windows.Forms.SendKeys]::SendWait($t)
Start-Sleep -Milliseconds 300
