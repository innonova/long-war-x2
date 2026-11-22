# Clicks a label on the game's screen as a player would: the screen read by Windows' OCR (ocr.ps1), the first line whose
# text holds Label (case-insensitive; spaces ignored) clicked at its centre with the real mouse (click.ps1). Prints the
# line clicked, or ERR with what was read (features/e2e-tests.md).
#   tools\test\click-label.ps1 "BUILD/BUY ITEMS" [-Right] [-Nth 2]
param([Parameter(Mandatory)][string]$Label, [switch]$Right, [int]$Nth = 1)
# ("=LABEL": the whole line exactly, not a line holding it: the main menu's LONG WAR beside LONG WAR: AIR WAR (DEMO).)
$exact = $Label.StartsWith('=')
if ($exact) { $Label = $Label.Substring(1) }
$want = ($Label -replace '\s', '').ToLowerInvariant()
# (OCR misses a label now and then (dim, fading in, light on dark): read again with other settings, and again a moment
# later, for up to three rounds, before giving up.)
$hits = @()
:rounds foreach ($round in 1..3) {
  foreach ($try in @(@(2, 1, 0, 0), @(2, 1, 0, 1), @(2, 2.5, 0, 1), @(2, 2.5, 0, 0), @(2, 1, 1, 1))) {
    $lines = & (Join-Path $PSScriptRoot 'ocr.ps1') -Scale $try[0] -Gain $try[1] -Bands:([bool]$try[2]) -Invert:([bool]$try[3])
    # (A line holding the label, or one that is the label with its last letters lost (OCR drops a trailing letter at a
    # frame's edge: "ENGINEERIN"): at least 85% of it, and the line no longer.)
    $min = [Math]::Max(4, [int][Math]::Ceiling($want.Length * 0.85))
    $hits = @($lines | Where-Object {
      if ($_ -notmatch '^(\d+) (\d+) (\d+) (\d+) (.*)$') { return $false }
      $t = ($Matches[5] -replace '\s', '').ToLowerInvariant()
      if ($exact) { ($t -replace '[^a-z0-9:]+$', '') -eq $want } else { $t.Contains($want) -or ($t.Length -ge $min -and $t.Length -le $want.Length -and $want.StartsWith($t)) }
    })
    if ($hits.Count -ge $Nth) { break rounds }
  }
  Start-Sleep -Milliseconds 1000
}
# (Not found as a line: by its words, OCR having joined it to a neighbour ("HANGA SITUATION ROO"): consecutive words on
# one line, each the label's word or that word's first letters (85%, at least 3).)
if ($hits.Count -lt $Nth) {
  $parts = @($Label.ToLowerInvariant() -split '\s+' | Where-Object { $_ })
  foreach ($try in @(@(2, 1, 1), @(2, 2.5, 0), @(2, 1, 0))) {
    $ws = @(& (Join-Path $PSScriptRoot 'ocr.ps1') -Scale $try[0] -Gain $try[1] -Invert:([bool]$try[2]) -Words | ForEach-Object { $f = $_ -split ' ', 6; [pscustomobject]@{ X = [int]$f[0]; Y = [int]$f[1]; W = [int]$f[2]; H = [int]$f[3]; L = [int]$f[4]; T = $f[5].ToLowerInvariant() } })
    $like = { param($t, $p) $t -eq $p -or ($t.Length -ge [Math]::Max(3, [int][Math]::Ceiling($p.Length * 0.85)) -and $p.StartsWith($t)) -or $t.StartsWith($p) }
    for ($i = 0; $i -le $ws.Count - $parts.Count; $i++) {
      $ok = $true
      for ($j = 0; $j -lt $parts.Count; $j++) { if ($ws[$i + $j].L -ne $ws[$i].L -or -not (& $like $ws[$i + $j].T $parts[$j])) { $ok = $false; break } }
      # (Exact: the words the whole of their line, each the label's word itself: "LONG WAR:" of LONG WAR: AIR WAR is not
      # LONG WAR.)
      if ($ok -and $exact) {
        $line = @($ws | Where-Object { $_.L -eq $ws[$i].L })
        for ($j = 0; $j -lt $parts.Count; $j++) { if ($ws[$i + $j].T -ne $parts[$j]) { $ok = $false } }
        if ($line.Count -ne $parts.Count) { $ok = $false }
      }
      if ($ok) {
        $a = $ws[$i]; $z = $ws[$i + $parts.Count - 1]
        $hits += ("{0} {1} {2} {3} {4}" -f $a.X, $a.Y, ($z.X + $z.W - $a.X), $a.H, (($ws[$i..($i + $parts.Count - 1)] | ForEach-Object { $_.T }) -join ' '))
        if ($hits.Count -ge $Nth) { break }
      }
    }
    if ($hits.Count -ge $Nth) { break }
  }
}
# (Still not found: the screen read in tiles (1100 x 180 of the UI, overlapping), each alone, plain and inverted: Windows'
# OCR reads some rows (the main menu's buttons along the bottom) only in a smaller picture.)
if ($hits.Count -lt $Nth) {
  $min = [Math]::Max(4, [int][Math]::Ceiling($want.Length * 0.85))
  :tiles foreach ($ty in 900, 0, 150, 300, 450, 600, 750) {
    foreach ($tx in 0, 410, 820) {
      foreach ($inv in $true, $false) {
        $lines = & (Join-Path $PSScriptRoot 'ocr.ps1') -Scale 2 -Invert:$inv -Region "$tx $ty 1100 180"
        $hits = @($lines | Where-Object {
          if ($_ -notmatch '^(\d+) (\d+) (\d+) (\d+) (.*)$') { return $false }
          $t = ($Matches[5] -replace '\s', '').ToLowerInvariant()
          if ($exact) { ($t -replace '[^a-z0-9:]+$', '') -eq $want } else { $t.Contains($want) -or ($t.Length -ge $min -and $t.Length -le $want.Length -and $want.StartsWith($t)) }
        })
        if ($hits.Count -ge $Nth) { break tiles }
      }
    }
  }
}
if ($hits.Count -lt $Nth) { "ERR no '$Label' on screen; read: " + (($lines | ForEach-Object { ($_ -split ' ', 5)[4] }) -join ' | '); exit 1 }
$null = $hits[$Nth - 1] -match '^(\d+) (\d+) (\d+) (\d+) (.*)$'
$x = [int]$Matches[1] + [int]$Matches[3] / 2; $y = [int]$Matches[2] + [int]$Matches[4] / 2
& (Join-Path $PSScriptRoot 'click.ps1') $x $y -Right:$Right
"clicked '$($Matches[5])' at $x $y"
