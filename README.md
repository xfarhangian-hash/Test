# MFarhangian Projects

GitHub profile: **https://github.com/MFarhangian**

## Repositories

| Repository | Description |
| --- | --- |
| [TFS-Sprint-Automation](https://github.com/MFarhangian/TFS-Sprint-Automation) | Azure DevOps sprint task automation for recurring backlog items |
| [Telegram](https://github.com/MFarhangian/Telegram) | Telegram bot for forwarding user messages to admin |

## Migrate from xfarhangian-hash/Test

This workspace was previously under `xfarhangian-hash/Test`. To publish everything under `MFarhangian`:

```powershell
$env:GITHUB_TOKEN = 'your-mfarhangian-pat'
.\scripts\migrate-to-mfarhangian.ps1
```

Or on Linux/macOS:

```bash
export GITHUB_TOKEN='your-mfarhangian-pat'
./scripts/migrate-to-mfarhangian.sh
```

The migration script creates/updates:

- `MFarhangian/TFS-Sprint-Automation` from branch `cursor/tfs-sprint-task-automation-9ce5`
- `MFarhangian/Telegram` from branch `cursor/telegram-bot-fa-a10e`

## TFS sprint tasks

```powershell
$env:AZURE_DEVOPS_PAT = 'your-tfs-pat'
.\scripts\create-sprint-tasks.ps1 -ParentId 58200
```

Configured sprint: `ImprovementOfInfrastructure\sprint 8-1405`  
Assignee: `Farhangian.Mohsen@okco.ir`
