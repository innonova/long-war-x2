# The control port's client on the test machine (tools/test/lw.sh runs it there): each command sent to the running
# game (LWX2Control, development builds), its answer printed. Two are the client's own, polling the game's state
# command over the connection (made again when a map load drops it):
#   wait <regex> [seconds, default 600]   until the state line matches
#   go <regex> [seconds, default 600]     the same, while skipping films and continuing screens (lw continue)
param([string]$Commands, [int]$Port = 7531)

$script:client = $null
function Connect {
  try {
    $script:client = New-Object Net.Sockets.TcpClient
    $script:client.Connect('127.0.0.1', $Port)
    $stream = $script:client.GetStream()
    $stream.ReadTimeout = 120000
    $script:reader = New-Object IO.StreamReader($stream, [Text.Encoding]::GetEncoding(28591))
    $script:writer = New-Object IO.StreamWriter($stream)
    $script:writer.NewLine = "`r`n"
    return $true
  } catch {
    return $false
  }
}
# A command's answer lines; $null when the connection is gone.
function Ask([string]$Command) {
  try {
    $script:writer.WriteLine($Command)
    $script:writer.Flush()
    $lines = @()
    while (($line = $script:reader.ReadLine()) -ne '.') {
      if ($null -eq $line) { return $null }
      $lines += $line
    }
    return , $lines
  } catch {
    return $null
  }
}

[Console]::OutputEncoding = [Text.Encoding]::UTF8
if (-not (Connect)) { "ERR the game is not listening on $Port"; exit 1 }
foreach ($cmd in [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Commands)).Split([char]10)) {
  if (-not $cmd) { continue }
  '> ' + $cmd
  if ($cmd -match '^(wait|go) (.+?)(?: (\d+))?$') {
    $go = $Matches[1] -eq 'go'
    $pattern = $Matches[2]
    $limit = if ($Matches[3]) { [int]$Matches[3] } else { 600 }
    $start = Get-Date
    $last = ''
    while ($true) {
      $answer = Ask 'state'
      if ($null -eq $answer) {
        if (-not (Get-Process XCom2 -ErrorAction SilentlyContinue)) { "ERR the game is gone (crashed or closed); last: $last"; break }
        # Between maps the game is not listening for a while.
        Start-Sleep 2
        [void](Connect)
      } else {
        $last = $answer[0]
        if ($last -match $pattern) { $last; break }
        if ($go) {
          if ($last -match 'movie=1') { [void](Ask 'stopmovie') }
          else { [void](Ask 'continue') }  # (continue touches only the screens it knows; the HUDs not at all)
        }
      }
      if (((Get-Date) - $start).TotalSeconds -gt $limit) { "ERR timed out waiting for $pattern; last: $last"; break }
      Start-Sleep 1
    }
    continue
  }
  $answer = Ask $cmd
  if ($null -eq $answer) { 'ERR connection closed'; [void](Connect) } else { $answer }
}
$script:client.Close()
