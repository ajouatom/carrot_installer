@echo off
setlocal EnableExtensions EnableDelayedExpansion

title Find Comma Device Parallel

set PLINK=plink.exe
set KEYFILE=id_rsa.ppk
set USER=comma
set HOSTKEY=ssh-ed25519 255 SHA256:phli1wMOyJjGlSUoC2hUoMkTegPzCpxgxoEBF4vwGCk
set TMP_OPEN=%TEMP%\comma_open_ips.txt
set TMP_AUTH=%TEMP%\comma_authcheck.txt

if not exist "%PLINK%" (
  echo [ERROR] %PLINK% not found in current folder.
  goto :end
)

if not exist "%KEYFILE%" (
  echo [ERROR] %KEYFILE% not found in current folder.
  goto :end
)

echo.
echo ==========================================
echo   Find Comma Device Parallel
echo ==========================================
echo.
echo Example prefix: 192.168.0
set /p NET=Enter network prefix: 

if "%NET%"=="" (
  echo [ERROR] Network prefix is required.
  goto :end
)

echo.
echo [INFO] Scan range : %NET%.1 - %NET%.255
echo [INFO] Mode       : PowerShell parallel scan + plink verify
echo.

if exist "%TMP_OPEN%" del /f /q "%TMP_OPEN%" >nul 2>nul

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$prefix='%NET%';" ^
  "$ips = 1..255 | ForEach-Object { \"$prefix.$_\" };" ^
  "$throttle = 32;" ^
  "$results = $ips | ForEach-Object -Parallel {" ^
  "  $ip = $_;" ^
  "  try {" ^
  "    $c = New-Object Net.Sockets.TcpClient;" ^
  "    $iar = $c.BeginConnect($ip, 22, $null, $null);" ^
  "    if ($iar.AsyncWaitHandle.WaitOne(120)) {" ^
  "      try { $c.EndConnect($iar) | Out-Null; $ip } catch {}" ^
  "    }" ^
  "  } finally {" ^
  "    if ($c) { $c.Close() }" ^
  "  }" ^
  "} -ThrottleLimit $throttle;" ^
  "$results | Set-Content '%TMP_OPEN%'" >nul

if not exist "%TMP_OPEN%" (
  echo [ERROR] Parallel port scan failed.
  goto :cleanup
)

echo [INFO] Open port 22 candidates:
type "%TMP_OPEN%"
echo.

for /f "usebackq delims=" %%I in ("%TMP_OPEN%") do (
  echo [*] Verifying %%I ...
  "%PLINK%" -batch -ssh -hostkey "%HOSTKEY%" -i "%KEYFILE%" -l %USER% %%I "echo COMMA_OK" > "%TMP_AUTH%" 2>nul
  findstr /C:"COMMA_OK" "%TMP_AUTH%" >nul 2>nul
  if not errorlevel 1 (
    echo.
    echo [FOUND] Comma device detected: %%I
    goto :cleanup
  )
)

echo [INFO] No matching comma device found.

:cleanup
if exist "%TMP_OPEN%" del /f /q "%TMP_OPEN%" >nul 2>nul
if exist "%TMP_AUTH%" del /f /q "%TMP_AUTH%" >nul 2>nul

:end
echo.
pause
endlocal