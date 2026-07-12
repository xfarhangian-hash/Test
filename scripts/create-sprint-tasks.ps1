#Requires -Version 5.1
<#
.SYNOPSIS
    Create sprint Tasks under recurring Product Backlog Items in Azure DevOps Server (TFS).

.EXAMPLE
    $env:AZURE_DEVOPS_PAT = 'your-personal-access-token'
    .\scripts\create-sprint-tasks.ps1

.EXAMPLE
    .\scripts\create-sprint-tasks.ps1 -ParentId 58200 -DryRun
#>
[CmdletBinding()]
param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot 'config.json'),
    [int[]]$ParentId = @(),
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-Config {
    param([string]$Path)
    Get-Content -Path $Path -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Invoke-TfsRequest {
    param(
        [string]$Method,
        [string]$Uri,
        [string]$Pat,
        $Body = $null,
        [string]$ContentType = 'application/json'
    )

    $headers = @{
        Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$Pat"))
        Accept = 'application/json'
    }

    $params = @{
        Method = $Method
        Uri = $Uri
        Headers = $headers
    }

    if ($null -ne $Body) {
        $params.ContentType = $ContentType
        if ($Body -is [string]) {
            $params.Body = $Body
        }
        else {
            $params.Body = ($Body | ConvertTo-Json -Depth 20 -Compress)
        }
    }

    try {
        return Invoke-RestMethod @params
    }
    catch {
        $response = $_.Exception.Response
        if ($response) {
            $reader = New-Object System.IO.StreamReader($response.GetResponseStream())
            $details = $reader.ReadToEnd()
            throw "Request failed ($($response.StatusCode.value__)) $details"
        }
        throw
    }
}

function Get-WorkItem {
    param(
        [string]$BaseUrl,
        [string]$Pat,
        [int]$Id
    )
    $uri = "$BaseUrl/_apis/wit/workitems/$Id`?api-version=7.0"
    Invoke-TfsRequest -Method GET -Uri $uri -Pat $Pat
}

function Find-ExistingChildTask {
    param(
        [string]$BaseUrl,
        [string]$Pat,
        [int]$ParentId,
        [string]$IterationPath,
        [string]$ChildType
    )

    $escapedIteration = $IterationPath.Replace("'", "''")
    $escapedChildType = $ChildType.Replace("'", "''")
    $wiql = @{
        query = @"
SELECT [System.Id], [System.Title]
FROM WorkItemLinks
WHERE
    [Source].[System.Id] = $ParentId
    AND [System.Links.LinkType] = 'System.LinkTypes.Hierarchy-Forward'
    AND [Target].[System.WorkItemType] = '$escapedChildType'
    AND [Target].[System.IterationPath] UNDER '$escapedIteration'
MODE (MustContain)
"@
    }

    $result = Invoke-TfsRequest -Method POST -Uri "$BaseUrl/_apis/wit/wiql?api-version=7.0" -Pat $Pat -Body $wiql
    $child = $result.workItemRelations |
        Where-Object { $_.target -and $_.target.id } |
        Select-Object -First 1

    if ($child) {
        return [pscustomobject]@{
            Id = [int]$child.target.id
            AlreadyExists = $true
        }
    }

    return $null
}

function New-ChildTask {
    param(
        [string]$BaseUrl,
        [string]$Pat,
        $Config,
        $Parent
    )

    $childType = [uri]::EscapeDataString($Config.childWorkItemType)
    $uri = "$BaseUrl/_apis/wit/workitems/`$$childType`?api-version=7.0"
    $title = $Parent.fields.'System.Title'

    $patch = @(
        @{ op = 'add'; path = '/fields/System.Title'; value = $title }
        @{ op = 'add'; path = '/fields/System.AssignedTo'; value = $Config.assignedTo }
        @{ op = 'add'; path = '/fields/System.IterationPath'; value = $Config.iterationPath }
        @{
            op = 'add'
            path = '/relations/-'
            value = @{
                rel = 'System.LinkTypes.Hierarchy-Reverse'
                url = $Parent.url
            }
        }
    )

    if ($Parent.fields.'System.AreaPath') {
        $patch += @{
            op = 'add'
            path = '/fields/System.AreaPath'
            value = $Parent.fields.'System.AreaPath'
        }
    }

    $created = Invoke-TfsRequest `
        -Method POST `
        -Uri $uri `
        -Pat $Pat `
        -Body ($patch | ConvertTo-Json -Depth 20 -Compress) `
        -ContentType 'application/json-patch+json'

    return [pscustomobject]@{
        Id = [int]$created.id
        Title = $title
        ParentId = [int]$Parent.id
        Url = $created.url
        Created = $true
    }
}

$config = Get-Config -Path $ConfigPath
$pat = $env:AZURE_DEVOPS_PAT
if (-not $pat) { $pat = $env:TFS_PAT }
if (-not $pat -and -not $DryRun) {
    throw 'Set AZURE_DEVOPS_PAT or TFS_PAT before running.'
}

$collection = [uri]::EscapeDataString($config.collection)
$project = [uri]::EscapeDataString($config.project)
$baseUrl = "$($config.serverUrl.TrimEnd('/'))/$collection/$project"

$parentIds = @()
if ($ParentId.Count -gt 0) {
    $parentIds = $ParentId
}
elseif ($config.parentIds) {
    $parentIds = @($config.parentIds)
}

if ($parentIds.Count -eq 0) {
  $wiql = @{
    query = @"
SELECT [System.Id]
FROM WorkItems
WHERE [System.TeamProject] = @project
  AND [System.WorkItemType] = '$($config.parentWorkItemType)'
  AND [System.AssignedTo] = '$($config.assignedTo)'
  AND [System.State] = '$($config.parentStateFilter)'
ORDER BY [System.Id]
"@
  }
  $result = Invoke-TfsRequest -Method POST -Uri "$baseUrl/_apis/wit/wiql?api-version=7.0" -Pat $pat -Body $wiql
  $parentIds = @($result.workItems | ForEach-Object { [int]$_.id })
}

Write-Host "Sprint: $($config.iterationPath)"
Write-Host "Parents: $($parentIds -join ', ')"

$results = @()
foreach ($parentId in $parentIds) {
    $parent = Get-WorkItem -BaseUrl $baseUrl -Pat $pat -Id $parentId
    $title = $parent.fields.'System.Title'
    Write-Host ""
    Write-Host "PBI $parentId`: $title"

    $existing = Find-ExistingChildTask `
        -BaseUrl $baseUrl `
        -Pat $pat `
        -ParentId $parentId `
        -IterationPath $config.iterationPath `
        -ChildType $config.childWorkItemType

    if ($existing) {
        Write-Host "  -> already has task $($existing.Id) in this sprint"
        $results += $existing
        continue
    }

    if ($DryRun) {
        Write-Host "  -> would create child task"
        $results += [pscustomobject]@{ ParentId = $parentId; Title = $title; DryRun = $true }
        continue
    }

    $created = New-ChildTask -BaseUrl $baseUrl -Pat $pat -Config $config -Parent $parent
    Write-Host "  -> created task $($created.Id)"
    $results += $created
}

Write-Host ""
Write-Host "Summary:"
foreach ($item in $results) {
    if ($item.Created) {
        Write-Host "  CREATED Task $($item.Id) under PBI $($item.ParentId)"
    }
    elseif ($item.AlreadyExists) {
        Write-Host "  SKIPPED existing Task $($item.Id)"
    }
    elseif ($item.DryRun) {
        Write-Host "  DRY-RUN would create task under PBI $($item.ParentId)"
    }
}
