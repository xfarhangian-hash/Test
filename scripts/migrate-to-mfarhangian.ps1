#Requires -Version 5.1
<#
.SYNOPSIS
    Migrate all project branches to https://github.com/MFarhangian

.EXAMPLE
    $env:GITHUB_TOKEN = 'ghp_...'
    .\scripts\migrate-to-mfarhangian.ps1
#>
[CmdletBinding()]
param(
    [string]$Owner = 'MFarhangian',
    [string]$SourceRepo = 'https://github.com/xfarhangian-hash/Test.git',
    [string]$WorkDir = (Join-Path $env:TEMP 'mfarhangian-migration')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $env:GITHUB_TOKEN) {
    throw 'Set GITHUB_TOKEN to a PAT for the MFarhangian account.'
}

function Invoke-GitHubApi {
    param(
        [string]$Method,
        [string]$Path,
        [object]$Body = $null
    )

    $params = @{
        Method = $Method
        Uri = "https://api.github.com$Path"
        Headers = @{
            Authorization = "Bearer $($env:GITHUB_TOKEN)"
            Accept = 'application/vnd.github+json'
            'User-Agent' = 'mfarhangian-migration'
        }
    }

    if ($null -ne $Body) {
        $params.ContentType = 'application/json'
        $params.Body = ($Body | ConvertTo-Json -Depth 10 -Compress)
    }

    return Invoke-RestMethod @params
}

$authUser = (Invoke-GitHubApi -Method GET -Path '/user').login
if ($authUser -ne $Owner) {
    throw "GITHUB_TOKEN belongs to '$authUser', expected '$Owner'."
}

function Ensure-Repo {
    param(
        [string]$Name,
        [string]$Description
    )

    try {
        Invoke-GitHubApi -Method GET -Path "/repos/$Owner/$Name" | Out-Null
        Write-Host "Repo $Owner/$Name already exists."
    }
    catch {
        Write-Host "Creating $Owner/$Name..."
        Invoke-GitHubApi -Method POST -Path '/user/repos' -Body @{
            name = $Name
            description = $Description
            private = $false
        } | Out-Null
    }
}

function Push-Branch {
    param(
        [string]$RepoPath,
        [string]$Branch,
        [string]$RepoName,
        [string]$RemoteRef = 'main'
    )

    Push-Location $RepoPath
  try {
        git checkout $Branch | Out-Null
        $remote = "https://x-access-token:$($env:GITHUB_TOKEN)@github.com/$Owner/$RepoName.git"
        git push $remote "${Branch}:refs/heads/$RemoteRef" --force
    }
    finally {
        Pop-Location
    }
}

if (Test-Path $WorkDir) {
    Remove-Item -Recurse -Force $WorkDir
}
New-Item -ItemType Directory -Path $WorkDir | Out-Null
git clone $SourceRepo (Join-Path $WorkDir 'source')

$sourcePath = Join-Path $WorkDir 'source'

Write-Host '==> Migrating TFS sprint automation'
Ensure-Repo -Name 'TFS-Sprint-Automation' -Description 'Azure DevOps sprint task automation for recurring backlog items'
Push-Branch -RepoPath $sourcePath -Branch 'cursor/tfs-sprint-task-automation-9ce5' -RepoName 'TFS-Sprint-Automation'

Write-Host '==> Migrating Telegram bot'
Ensure-Repo -Name 'Telegram' -Description 'Telegram bot for forwarding messages to admin'
Push-Branch -RepoPath $sourcePath -Branch 'cursor/telegram-bot-fa-a10e' -RepoName 'Telegram'

Write-Host ''
Write-Host 'Migration complete:'
Write-Host "  https://github.com/$Owner/TFS-Sprint-Automation"
Write-Host "  https://github.com/$Owner/Telegram"
