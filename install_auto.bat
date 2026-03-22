@echo off
setlocal EnableExtensions EnableDelayedExpansion

title OpenPilot Auto Installer

set PLINK=plink.exe
set KEYFILE=id_rsa.ppk
set USER=comma
set HOSTKEY=ssh-ed25519 255 SHA256:phli1wMOyJjGlSUoC2hUoMkTegPzCpxgxoEBF4vwGCk
set TMP_PORT=%TEMP%\comma_portcheck.txt
set TMP_AUTH=%TEMP%\comma_authcheck.txt
set REMOTE_SCRIPT=%TEMP%\remote_install_%RANDOM%.sh

if not exist "%PLINK%" (
  echo [ERROR] plink.exe not found.
  goto :end
)

if not exist "%KEYFILE%" (
  echo [ERROR] id_rsa.ppk not found.
  goto :end
)

echo.
echo ==========================================
echo   OpenPilot Auto Installer
echo ==========================================
echo.
echo Example prefix: 192.168.0
set /p NET=Enter network prefix: 
if "%NET%"=="" (
  echo [ERROR] Network prefix is required.
  goto :end
)

set /p BRANCH=Enter branch name: 
if "%BRANCH%"=="" (
  echo [ERROR] Branch is required.
  goto :end
)

echo.
echo [INFO] Scan range : %NET%.1 - %NET%.255
echo [INFO] Branch     : %BRANCH%
echo.

set FOUND_IP=

for /l %%i in (1,1,255) do (
  set IP=%NET%.%%i
  <nul set /p="[*] Checking !IP!... "

  powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ip='!IP!'; $c=New-Object Net.Sockets.TcpClient; try { $iar=$c.BeginConnect($ip,22,$null,$null); if($iar.AsyncWaitHandle.WaitOne(120)) { try { $c.EndConnect($iar) | Out-Null; 'OPEN' } catch {} } } finally { if ($c) { $c.Close() } }" > "%TMP_PORT%" 2>nul

  set PORTOPEN=
  set /p PORTOPEN=<"%TMP_PORT%"

  if /i not "!PORTOPEN!"=="OPEN" (
    echo closed
  ) else (
    echo port 22 open
    "%PLINK%" -batch -ssh -hostkey "%HOSTKEY%" -i "%KEYFILE%" -l %USER% !IP! "echo COMMA_OK" > "%TMP_AUTH%" 2>nul
    findstr /C:"COMMA_OK" "%TMP_AUTH%" >nul 2>nul
    if not errorlevel 1 (
      set FOUND_IP=!IP!
      echo.
      echo [FOUND] Comma device detected: !IP!
      goto :install
    ) else (
      echo     not target
    )
  )
)

echo.
echo [ERROR] No matching comma device found.
goto :cleanup

:install
echo.
echo [INFO] Creating remote install script...

(
  echo set -e
  echo BRANCH='%BRANCH%'
  echo cd /data ^|^| exit 11
  echo echo "[STEP] Current folder:"
  echo pwd
  echo echo "[STEP] Disk usage:"
  echo df -h /data ^|^| true
  echo echo "[STEP] Removing temp folder openpilot_new"
  echo rm -rf openpilot_new 2^>/dev/null ^|^| true
  echo echo "[STEP] Removing previous backup openpilot_stock_prev"
  echo rm -rf openpilot_stock_prev 2^>/dev/null ^|^| true
  echo if [ -d openpilot_stock ]; then
  echo ^  echo "[STEP] Moving openpilot_stock -^> openpilot_stock_prev"
  echo ^  mv openpilot_stock openpilot_stock_prev
  echo fi
  echo if [ -d openpilot ]; then
  echo ^  echo "[STEP] Moving openpilot -^> openpilot_stock"
  echo ^  mv openpilot openpilot_stock
  echo else
  echo ^  echo "[STEP] openpilot folder not found, skip backup"
  echo fi
  echo echo "[STEP] Cloning branch into openpilot_new"
  echo if git clone --progress -b "$BRANCH" https://github.com/ajouatom/openpilot.git openpilot_new; then
  echo ^  echo "[STEP] Clone success"
  echo ^  echo "[STEP] Moving openpilot_new -^> openpilot"
  echo ^  mv openpilot_new openpilot
  echo ^  echo "[STEP] Cleaning old backup openpilot_stock_prev"
  echo ^  rm -rf openpilot_stock_prev 2^>/dev/null ^|^| true
  echo ^  echo "[STEP] Creating /data/continue.sh"
  echo ^  cat ^> /data/continue.sh ^<^< 'EOF'
  echo ^#!/usr/bin/env bash
  echo.
  echo ^cd /data/openpilot
  echo ^exec ./launch_openpilot.sh
  echo ^EOF
  echo ^  chmod +x /data/continue.sh
  echo ^  echo "[STEP] Install completed"
  echo ^  echo "[STEP] Rebooting"
  echo ^  sudo reboot ^|^| reboot
  echo else
  echo ^  echo "[ERROR] Clone failed"
  echo ^  rm -rf openpilot_new 2^>/dev/null ^|^| true
  echo ^  if [ -d openpilot ]; then
  echo ^    echo "[STEP] Removing incomplete openpilot"
  echo ^    rm -rf openpilot 2^>/dev/null ^|^| true
  echo ^  fi
  echo ^  if [ -d openpilot_stock ]; then
  echo ^    echo "[STEP] Restoring openpilot_stock -^> openpilot"
  echo ^    mv openpilot_stock openpilot
  echo ^  fi
  echo ^  if [ -d openpilot_stock_prev ] ^&^& [ ! -d openpilot_stock ]; then
  echo ^    echo "[STEP] Restoring openpilot_stock_prev -^> openpilot_stock"
  echo ^    mv openpilot_stock_prev openpilot_stock
  echo ^  fi
  echo ^  exit 13
  echo fi
) > "%REMOTE_SCRIPT%"

echo.
echo ==========================================
echo   Live Remote Output
echo ==========================================
echo.

"%PLINK%" -ssh -batch -hostkey "%HOSTKEY%" -i "%KEYFILE%" -m "%REMOTE_SCRIPT%" %USER%@%FOUND_IP%
set RC=%ERRORLEVEL%

echo.
echo ==========================================
echo.

if not "%RC%"=="0" (
  echo [ERROR] Remote install failed. Exit code: %RC%
) else (
  echo [INFO] Remote install finished successfully.
)

:cleanup
if exist "%TMP_PORT%" del /f /q "%TMP_PORT%" >nul 2>nul
if exist "%TMP_AUTH%" del /f /q "%TMP_AUTH%" >nul 2>nul
if exist "%REMOTE_SCRIPT%" del /f /q "%REMOTE_SCRIPT%" >nul 2>nul

:end
echo.
pause
endlocal