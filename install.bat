@echo off
setlocal EnableExtensions

title OpenPilot Remote Installer

echo.
echo ==========================================
echo   OpenPilot Remote Installer
echo ==========================================
echo.

set /p IP=Enter device IP: 
if "%IP%"=="" (
  echo [ERROR] IP is required.
  goto :end
)

set /p BRANCH=Enter branch name: 
if "%BRANCH%"=="" (
  echo [ERROR] Branch is required.
  goto :end
)

set USER=comma
set KEYFILE=id_rsa.ppk
set PLINK=plink.exe
set REMOTE_SCRIPT=%TEMP%\remote_install_%RANDOM%.sh

if not exist "%PLINK%" (
  echo [ERROR] %PLINK% not found in current folder.
  goto :end
)

if not exist "%KEYFILE%" (
  echo [ERROR] %KEYFILE% not found in current folder.
  goto :end
)

echo.
echo [INFO] Target IP   : %IP%
echo [INFO] Branch      : %BRANCH%
echo [INFO] User        : %USER%
echo.

echo [INFO] First SSH check...
echo       If a host key question appears, type y and press Enter.
echo.

"%PLINK%" -ssh %USER%@%IP% -i "%KEYFILE%" "exit"
if errorlevel 1 (
  echo.
  echo [ERROR] SSH check failed.
  echo [HINT] Check:
  echo        1. IP is correct
  echo        2. device is on Wi-Fi
  echo        3. id_rsa.ppk is correct
  echo        4. host key was accepted
  goto :end
)

echo.
echo [INFO] Creating remote script...
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

if errorlevel 1 (
  echo [ERROR] Failed to create remote script.
  goto :cleanup
)

echo.
echo ==========================================
echo   Live Remote Output
echo ==========================================
echo.

"%PLINK%" -ssh -batch -i "%KEYFILE%" -m "%REMOTE_SCRIPT%" %USER%@%IP%
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
if exist "%REMOTE_SCRIPT%" del /f /q "%REMOTE_SCRIPT%" >nul 2>nul

:end
echo.
pause
endlocal