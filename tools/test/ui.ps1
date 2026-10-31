# Windows UI Automation on a window found by its title (a regular expression):
#   ui.ps1 <title> set <control name> <text>   a field's text
#   ui.ps1 <title> press <control name>        a button
#   ui.ps1 <title> list                        the window's named controls (to find names)
param([Parameter(Mandatory)][string]$Title, [Parameter(Mandatory)][string]$Action, [string]$Name, [string]$Text)
Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes
$A = [System.Windows.Automation.AutomationElement]
$root = $A::RootElement
# Top-level windows first; then any window (dialogs hang under their owner).
$isWindow = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::Window)
$win = $root.FindAll([System.Windows.Automation.TreeScope]::Children, $isWindow) | Where-Object { $_.Current.Name -match $Title } | Select-Object -First 1
if (-not $win) { $win = $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, $isWindow) | Where-Object { $_.Current.Name -match $Title } | Select-Object -First 1 }
if (-not $win) { "no window $Title"; exit 1 }
$all = $win.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)
if ($Action -eq 'list') {
  $all | ForEach-Object { "{0} | {1} | {2}" -f $_.Current.ControlType.ProgrammaticName, $_.Current.Name, $_.Current.AutomationId } | Where-Object { $_ -notmatch '\|  \| $' } | Select-Object -First 120
  exit
}
$el = $all | Where-Object { $_.Current.Name -eq $Name -or $_.Current.AutomationId -eq $Name } | Where-Object {
  if ($Action -eq 'set') { $_.Current.ControlType -eq [System.Windows.Automation.ControlType]::Edit } else { $true } } | Select-Object -First 1
if (-not $el) { "no control $Name"; exit 1 }
switch ($Action) {
  'set' { $el.GetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern).SetValue($Text); "set $Name" }
  'press' {
    $p = $null
    if ($el.TryGetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern, [ref]$p)) { $p.Invoke() }
    elseif ($el.TryGetCurrentPattern([System.Windows.Automation.TogglePattern]::Pattern, [ref]$p)) { $p.Toggle() }
    elseif ($el.TryGetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern, [ref]$p)) { $p.Select() }
    else { "no way to press $Name"; exit 1 }
    "pressed $Name"
  }
}
