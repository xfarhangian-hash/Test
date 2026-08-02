# Fix red `mssql-ha` MCP on Windows

After a Windows reinstall/change, Node path and `mcp.json` paths usually break.

## One-shot repair

In PowerShell:

```powershell
cd <path-to>\Test\windows
powershell -ExecutionPolicy Bypass -File .\fix-mcp.ps1
```

The script will:

1. Find or install Node.js (via winget if needed)
2. Write `%USERPROFILE%\.cursor\mcp.json` with an absolute path to `start-mssql-mcp.cmd`
3. Ask for the password of `OKCO\Farhangian.Mohsen`
4. Smoke-test that the MCP process starts

Then **fully quit Cursor** (not only close the window) and reopen.

## Auth

- Domain user: `OKCO\Farhangian.Mohsen`
- NTLM password goes only in Cursor MCP env (not committed to git)
