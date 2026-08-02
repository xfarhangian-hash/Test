@echo off
setlocal EnableExtensions
REM Launcher for Cursor MCP on Windows (works after OS reinstall if Node is installed).
REM Repo-relative config — do not hardcode username paths here.

set "REPO=%~dp0.."
for %%I in ("%REPO%") do set "REPO=%%~fI"
set "MSSQL_MCP_CONFIG=%REPO%\mssql-mcp.yaml"

if not defined MSSQL_USER set "MSSQL_USER=Farhangian.Mohsen"
if not defined MSSQL_PASSWORD (
  echo [mssql-ha] MSSQL_PASSWORD is missing. Set it in Cursor mcp.json env. 1>&2
  exit /b 1
)
if not exist "%MSSQL_MCP_CONFIG%" (
  echo [mssql-ha] Config not found: %MSSQL_MCP_CONFIG% 1>&2
  exit /b 1
)

set "NPX="
where npx >nul 2>&1 && set "NPX=npx"
if not defined NPX if exist "%ProgramFiles%\nodejs\npx.cmd" set "NPX=%ProgramFiles%\nodejs\npx.cmd"
if not defined NPX if exist "%LocalAppData%\Programs\nodejs\npx.cmd" set "NPX=%LocalAppData%\Programs\nodejs\npx.cmd"
if not defined NPX (
  echo [mssql-ha] Node.js/npx not found. Install Node LTS from https://nodejs.org then restart Cursor. 1>&2
  exit /b 1
)

cd /d "%REPO%"
"%NPX%" -y @tugberkgunver/mcp-sqlserver --config "%MSSQL_MCP_CONFIG%"
exit /b %ERRORLEVEL%
