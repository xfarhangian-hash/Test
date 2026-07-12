# TFS Sprint Task Automation

Scripts for creating sprint Tasks under recurring Product Backlog Items in Azure DevOps Server (`azure.okco.ir`).

## Quick start

1. Create a PAT with **Work Items (Read & Write)** scope in TFS.
2. From a machine on the corporate network:

```powershell
$env:AZURE_DEVOPS_PAT = 'your-pat'
.\scripts\create-sprint-tasks.ps1 -ParentId 58200
```

Or with Python:

```bash
export AZURE_DEVOPS_PAT='your-pat'
python3 scripts/create-sprint-tasks.py --parent-id 58200
```

3. Edit `scripts/config.json` to change sprint, assignee, or the full list of recurring PBI ids.

## Current sprint example

- Parent PBI: `58200` — مانیتورینگ جاب های سرورهای عراق
- Sprint: `ImprovementOfInfrastructure\sprint 8-1405`
- Assignee: `Farhangian.Mohsen@okco.ir`

The script creates a child **Task** with the same title, links it to the parent PBI, and skips creation if a task already exists in that sprint.
