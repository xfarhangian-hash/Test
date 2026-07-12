@echo off
cd /d "%~dp0"
echo Stopping bot processes...
for /f "tokens=2" %%a in ('tasklist /fi "imagename eq python.exe" /fo list ^| find "PID:"') do (
    wmic process where "ProcessId=%%a" get CommandLine 2>nul | find /i "bot.main" >nul && taskkill /F /PID %%a >nul 2>&1
)
if exist ".bot.lock" del /f ".bot.lock"
echo Done. You can start the bot again with start.bat
pause
