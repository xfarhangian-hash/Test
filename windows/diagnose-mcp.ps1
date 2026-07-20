# Run in PowerShell (as your normal user on the domain PC):
#   cd C:\Users\farhangian.mohsen\Desktop\Git\Test\windows
#   powershell -ExecutionPolicy Bypass -File .\diagnose-mcp.ps1

$ErrorActionPreference = "Continue"
$repo = "C:\Users\farhangian.mohsen\Desktop\Git\Test"
$yaml = Join-Path $repo "mssql-mcp.yaml"

Write-Host "=== 1) Node / npx ===" -ForegroundColor Cyan
Get-Command node -ErrorAction SilentlyContinue | Format-List
Get-Command npx -ErrorAction SilentlyContinue | Format-List
node -v
npx -v

Write-Host "`n=== 2) Config files ===" -ForegroundColor Cyan
Test-Path $yaml
Test-Path (Join-Path $repo ".cursor\mcp.json")
Test-Path "$env:USERPROFILE\.cursor\mcp.json"

Write-Host "`n=== 3) DNS / SQL port ===" -ForegroundColor Cyan
foreach ($h in @("gig-dc1-g545", "GIG-DC1-P451")) {
  try { Resolve-DnsName $h -ErrorAction Stop | Select-Object -First 1 Name, IPAddress } catch { Write-Host "$h : DNS failed - $_" }
  Test-NetConnection -ComputerName $h -Port 1433 -WarningAction SilentlyContinue | Select-Object ComputerName, TcpTestSucceeded
}

Write-Host "`n=== 4) Start MCP server (10s) ===" -ForegroundColor Cyan
$env:MSSQL_USER = "Farhangian.Mohsen"
$env:MSSQL_PASSWORD = Read-Host "Windows password for OKCO\Farhangian.Mohsen" -AsSecureString
$ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($env:MSSQL_PASSWORD)
$plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto($ptr)
$env:MSSQL_PASSWORD = $plain

Push-Location $repo
$job = Start-Job {
  param($y)
  npx -y @tugberkgunver/mcp-sqlserver --config $y 2>&1
} -ArgumentList $yaml
Start-Sleep -Seconds 12
Receive-Job $job
Stop-Job $job -ErrorAction SilentlyContinue
Remove-Job $job -ErrorAction SilentlyContinue
Pop-Location

Write-Host "`n=== 5) NTLM SQL login test ===" -ForegroundColor Cyan
$testJs = @"
const sql = require('mssql');
(async () => {
  try {
    const pool = await sql.connect({
      server: 'gig-dc1-g545',
      database: 'master',
      authentication: {
        type: 'ntlm',
        options: { domain: 'OKCO', userName: 'Farhangian.Mohsen', password: process.env.MSSQL_PASSWORD }
      },
      options: { encrypt: true, trustServerCertificate: true }
    });
    const r = await pool.request().query('SELECT @@SERVERNAME AS s, SYSTEM_USER AS u');
    console.log('OK', r.recordset[0]);
    await pool.close();
  } catch (e) { console.error('FAIL', e.message); process.exit(1); }
})();
"@
$tmp = Join-Path $env:TEMP "ha-sql-test"
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
Set-Content -Path (Join-Path $tmp "test.js") -Value $testJs
Push-Location $tmp
if (-not (Test-Path node_modules)) { npm init -y | Out-Null; npm install mssql@11 --silent }
node test.js
Pop-Location

Write-Host "`nDone. Send this full output to support/chat." -ForegroundColor Green
