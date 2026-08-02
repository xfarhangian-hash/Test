# Repair / reinstall mssql-ha MCP after Windows change.
# Run in PowerShell:
#   cd C:\Users\<you>\Desktop\Git\Test\windows
#   powershell -ExecutionPolicy Bypass -File .\fix-mcp.ps1

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repo = (Resolve-Path (Join-Path $scriptDir "..")).Path
$yaml = Join-Path $repo "mssql-mcp.yaml"
$launcher = Join-Path $scriptDir "start-mssql-mcp.cmd"
$userMcpDir = Join-Path $env:USERPROFILE ".cursor"
$userMcp = Join-Path $userMcpDir "mcp.json"
$projectMcpDir = Join-Path $repo ".cursor"
$projectMcp = Join-Path $projectMcpDir "mcp.json"

Write-Host "Repo: $repo"
Write-Host "User: $env:USERNAME  Profile: $env:USERPROFILE"

if (-not (Test-Path $yaml)) { throw "Missing $yaml — open/clone the Test repo first." }
if (-not (Test-Path $launcher)) { throw "Missing $launcher" }

# --- Node.js ---
function Find-Npx {
  $cmd = Get-Command npx -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  $candidates = @(
    "$env:ProgramFiles\nodejs\npx.cmd",
    "${env:ProgramFiles(x86)}\nodejs\npx.cmd",
    "$env:LocalAppData\Programs\nodejs\npx.cmd"
  )
  foreach ($c in $candidates) { if (Test-Path $c) { return $c } }
  return $null
}

$npx = Find-Npx
if (-not $npx) {
  Write-Host "Node.js not found. Trying winget install..." -ForegroundColor Yellow
  $winget = Get-Command winget -ErrorAction SilentlyContinue
  if ($winget) {
    winget install -e --id OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "User")
    $npx = Find-Npx
  }
}
if (-not $npx) {
  throw "Node.js/npx still missing. Install Node LTS from https://nodejs.org , then re-run this script and restart Cursor."
}
Write-Host "npx: $npx"
& node -v
& npx -v

# --- Password ---
$secure = Read-Host "Windows password for OKCO\Farhangian.Mohsen" -AsSecureString
$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
$password = [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
if ([string]::IsNullOrWhiteSpace($password)) { throw "Password is required for NTLM." }

# --- mcp.json (absolute launcher path — required by Cursor) ---
$mcpObject = [ordered]@{
  mcpServers = [ordered]@{
    "mssql-ha" = [ordered]@{
      command = $launcher
      args    = @()
      env     = [ordered]@{
        MSSQL_USER     = "Farhangian.Mohsen"
        MSSQL_PASSWORD = $password
      }
    }
  }
}
$json = $mcpObject | ConvertTo-Json -Depth 8

New-Item -ItemType Directory -Force -Path $userMcpDir | Out-Null
New-Item -ItemType Directory -Force -Path $projectMcpDir | Out-Null

# Backup existing user mcp.json
if (Test-Path $userMcp) {
  Copy-Item $userMcp "$userMcp.bak-$(Get-Date -Format yyyyMMdd-HHmmss)" -Force
}

# Merge: keep other servers if present, replace mssql-ha
if (Test-Path $userMcp) {
  try {
    $existing = Get-Content $userMcp -Raw | ConvertFrom-Json
    if ($existing.mcpServers) {
      $existing.mcpServers | Add-Member -NotePropertyName "mssql-ha" -NotePropertyValue $mcpObject.mcpServers."mssql-ha" -Force
      $json = $existing | ConvertTo-Json -Depth 8
    }
  } catch {
    Write-Host "Could not merge old mcp.json; rewriting mssql-ha only." -ForegroundColor Yellow
  }
}

Set-Content -Path $userMcp -Value $json -Encoding UTF8
# Project copy without password placeholder for git safety — use env injection locally
$projectCopy = [ordered]@{
  mcpServers = [ordered]@{
    "mssql-ha" = [ordered]@{
      command = $launcher
      args    = @()
      env     = [ordered]@{
        MSSQL_USER     = "Farhangian.Mohsen"
        MSSQL_PASSWORD = "REPLACE_WITH_WINDOWS_PASSWORD"
      }
    }
  }
}
($projectCopy | ConvertTo-Json -Depth 8) | Set-Content -Path $projectMcp -Encoding UTF8

Write-Host "Wrote: $userMcp" -ForegroundColor Green
Write-Host "Wrote: $projectMcp (password placeholder only)" -ForegroundColor Green

# --- Smoke test MCP process (stdio) ---
Write-Host "`nSmoke-testing MCP start (8s)..." -ForegroundColor Cyan
$env:MSSQL_USER = "Farhangian.Mohsen"
$env:MSSQL_PASSWORD = $password
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $launcher
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
$p = [Diagnostics.Process]::Start($psi)
Start-Sleep -Seconds 8
if (-not $p.HasExited) { $p.Kill() }
$out = $p.StandardError.ReadToEnd() + $p.StandardOutput.ReadToEnd()
Write-Host $out
if ($out -match "Connected and ready") {
  Write-Host "`nOK: MCP server starts. Fully quit Cursor and reopen, then check Tools & MCP (green + tools)." -ForegroundColor Green
} else {
  Write-Host "`nMCP did not report ready. Fix Node/network from the log above, then re-run." -ForegroundColor Red
  exit 1
}
