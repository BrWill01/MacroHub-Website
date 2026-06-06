@echo off
setlocal
cd /d "%~dp0"

choice /m "Download and install MacroHub? This closes MacroHub, replaces the old install, opens the new app, and cleans old MacroHub files"
if errorlevel 2 exit /b 0

where node >nul 2>nul
if errorlevel 1 (
  echo Node.js is required before MacroHub can be installed.
  start https://nodejs.org/en/download
  pause
  exit /b 1
)

where npm >nul 2>nul
if errorlevel 1 (
  echo npm was not found. Reinstall Node.js from https://nodejs.org/en/download and try again.
  start https://nodejs.org/en/download
  pause
  exit /b 1
)

echo Closing any running MacroHub...
taskkill /IM MacroHub.exe /F >nul 2>nul

echo Installing dependencies...
set "npm_config_cache=%TEMP%\macrohub-npm-cache"
call npm install
if errorlevel 1 pause & exit /b 1

echo Building MacroHub...
if exist "dist" rmdir /s /q "dist"
call npm run package:win
if errorlevel 1 pause & exit /b 1

set "INSTALL_DIR=%LOCALAPPDATA%\Programs\MacroHub"
set "START_MENU=%APPDATA%\Microsoft\Windows\Start Menu\Programs"

echo Replacing old installed MacroHub...
if exist "%INSTALL_DIR%" rmdir /s /q "%INSTALL_DIR%"
mkdir "%INSTALL_DIR%"
xcopy /e /i /y "%cd%\dist" "%INSTALL_DIR%" >nul

powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=(New-Object -COM WScript.Shell).CreateShortcut('%START_MENU%\MacroHub.lnk'); $s.TargetPath='%INSTALL_DIR%\MacroHub.exe'; $s.WorkingDirectory='%INSTALL_DIR%'; $s.Save()"

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\MacroHub" /v DisplayName /t REG_SZ /d "MacroHub" /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\MacroHub" /v DisplayVersion /t REG_SZ /d "1.0.0" /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\MacroHub" /v InstallLocation /t REG_SZ /d "%INSTALL_DIR%" /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\MacroHub" /v Publisher /t REG_SZ /d "MacroHub" /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\MacroHub" /v UninstallString /t REG_SZ /d "cmd /c taskkill /IM MacroHub.exe /F >nul 2>nul & rmdir /s /q \"%INSTALL_DIR%\" & del \"%START_MENU%\MacroHub.lnk\"" /f >nul

echo Cleaning MacroHub-only temporary files...
if exist "dist" rmdir /s /q "dist"
if exist "node_modules" rmdir /s /q "node_modules"
for %%f in ("%~dp0..\MacroHub*.zip" "%~dp0..\MacroHubDeveloper*.zip") do if exist "%%~f" del /q "%%~f"

echo Opening MacroHub...
start "" "%INSTALL_DIR%\MacroHub.exe"
pause
