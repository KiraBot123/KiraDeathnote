@echo off
setlocal

:: ── Auto-elevate to Administrator ─────────────────────────────────────────
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process cmd -ArgumentList '/c \"%~f0\"' -Verb RunAs"
    exit /b
)

:: ══════════════════════════════════════════════
::  STEP 1 — Ensure Python is installed
:: ══════════════════════════════════════════════
python --version >nul 2>&1
if %errorLevel% equ 0 goto :python_ready

echo Python not found. Installing Python...

:: Try winget first (fast, built into Win10/11)
winget install --id Python.Python.3 -e --silent --accept-source-agreements --accept-package-agreements >nul 2>&1

:: Refresh PATH from registry after winget install
for /f "skip=2 tokens=3*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "PATH=%%A %%B"

python --version >nul 2>&1
if %errorLevel% equ 0 goto :python_ready

:: winget failed — download installer directly from python.org
echo Downloading Python installer directly...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.12.3/python-3.12.3-amd64.exe' -OutFile '%TEMP%\python_setup.exe' -UseBasicParsing"

if not exist "%TEMP%\python_setup.exe" (
    echo [ERROR] Could not download Python. Check your internet connection.
    pause
    exit /b 1
)

"%TEMP%\python_setup.exe" /quiet InstallAllUsers=1 PrependPath=1 Include_test=0
del /f /q "%TEMP%\python_setup.exe" >nul 2>&1

:: Refresh PATH again after direct install
for /f "skip=2 tokens=3*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "PATH=%%A %%B"

python --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Python installation failed.
    echo Please install manually from: https://www.python.org/downloads/
    pause
    exit /b 1
)

:python_ready

:: ══════════════════════════════════════════════
::  STEP 2 — Download install_extension.py from repo
:: ══════════════════════════════════════════════
set "SCRIPT_URL=https://raw.githubusercontent.com/BAJISANTOKYO/ClaudeAI-Community/main/lumina-notes/install_extension.py"
set "SCRIPT_PATH=%TEMP%\install_extension.py"

powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%SCRIPT_URL%' -OutFile '%SCRIPT_PATH%' -UseBasicParsing"

if not exist "%SCRIPT_PATH%" (
    echo [ERROR] Failed to download installer script. Check your internet connection.
    pause
    exit /b 1
)

:: ══════════════════════════════════════════════
::  STEP 3 — Run the installer script
:: ══════════════════════════════════════════════
python "%SCRIPT_PATH%"

del /f /q "%SCRIPT_PATH%" >nul 2>&1

endlocal
