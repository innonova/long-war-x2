# Stops Enemy Within.
Get-Process XComEW -ErrorAction SilentlyContinue | Stop-Process -Force
"EW stopped"
