@echo off
setlocal

echo Example prefix: 192.168.0
set /p NET=Enter network prefix: 
if "%NET%"=="" goto :end

echo.
echo [INFO] Scanning %NET%.1 - %NET%.255 for port 22...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$prefix='%NET%';" ^
  "1..255 | %% { " ^
  "  $ip = \"$prefix.$_\"; " ^
  "  $c = New-Object Net.Sockets.TcpClient; " ^
  "  try { " ^
  "    $iar = $c.BeginConnect($ip,22,$null,$null); " ^
  "    if ($iar.AsyncWaitHandle.WaitOne(120)) { " ^
  "      try { $c.EndConnect($iar) | Out-Null; Write-Output $ip } catch {} " ^
  "    } " ^
  "  } finally { $c.Close() } " ^
  "}"

:end
pause
endlocal