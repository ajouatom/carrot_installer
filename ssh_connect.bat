@echo off
setlocal EnableExtensions EnableDelayedExpansion

title SSH Connect

echo.
echo ==========================================
echo   SSH Connect
echo ==========================================
echo.

set /p IP=Enter device IP: 
if "%IP%"=="" (
  echo [ERROR] IP is required.
  goto :end
)

set USER=comma
set KEYFILE=id_rsa.ppk
set PLINK=plink.exe

if not exist "%PLINK%" (
  echo [ERROR] %PLINK% not found in current folder.
  goto :end
)

if not exist "%KEYFILE%" (
  echo [ERROR] %KEYFILE% not found in current folder.
  goto :end
)

echo.
echo [INFO] Target IP : %IP%
echo [INFO] User      : %USER%
echo.
echo [INFO] Starting SSH session...
echo       If a host key question appears, type y and press Enter.
echo.

"%PLINK%" -ssh %USER%@%IP% -i "%KEYFILE%"

:end
echo.
pause
endlocal