@echo off
chcp 65001 >nul
cd /d "%~dp0"

if not exist ".env" (
    echo ERROR: .env file not found in this folder.
    echo Copy .env.example to .env and set TELEGRAM_BOT_TOKEN.
    echo Path: %~dp0.env
    pause
    exit /b 1
)

if not exist ".venv\Scripts\python.exe" (
    echo Creating virtual environment...
    py -m venv .venv
)

echo Installing dependencies...
.venv\Scripts\python.exe -m pip install -r requirements.txt

echo Starting bot...
.venv\Scripts\python.exe -m bot.main
pause
