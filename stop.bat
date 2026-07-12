@echo off
cd /d "%~dp0"
echo ========================================
echo   Stopping ALL bot instances
echo ========================================

REM Kill any python running bot.main
for /f "tokens=2" %%a in ('tasklist /fi "imagename eq python.exe" /fo list 2^>nul ^| find "PID:"') do (
    wmic process where "ProcessId=%%a" get CommandLine 2>nul | find /i "bot.main" >nul
    if not errorlevel 1 (
        echo Killing PID %%a
        taskkill /F /PID %%a >nul 2>&1
    )
)

if exist ".bot.lock" del /f ".bot.lock"

echo.
echo Waiting 5 seconds for Telegram to release connection...
timeout /t 5 /nobreak >nul

echo.
echo Resetting Telegram webhook/polling via API...
.venv\Scripts\python.exe -c "import os; from dotenv import load_dotenv; load_dotenv(); t=os.getenv('TELEGRAM_BOT_TOKEN','').strip(); import urllib.request; urllib.request.urlopen('https://api.telegram.org/bot'+t+'/deleteWebhook?drop_pending_updates=true') if t else None; print('Webhook cleared.')" 2>nul

echo.
echo Done. Now run start.bat (only once!)
pause
