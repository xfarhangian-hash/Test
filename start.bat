@echo off
cd /d "%~dp0"

if not exist ".venv\Scripts\python.exe" (
    echo Creating virtual environment...
    py -m venv .venv
)

echo Installing dependencies...
.venv\Scripts\python.exe -m pip install -r requirements.txt

echo Starting bot...
.venv\Scripts\python.exe -m bot.main
pause
