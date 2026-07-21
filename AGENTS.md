# AGENTS.md

## Cursor Cloud specific instructions

### Repository layout (important, non-obvious)

This repo is **not** a single app on `main`. The `main` branch is an empty placeholder
(`README.md` = `# Test`). Each product lives on its own feature branch and they are
independent (no shared packages). To work on a product, check out its branch (or add a
git worktree) first.

| Product | Branch | Runnable in Cursor Cloud? |
| --- | --- | --- |
| Telegram forward-bot (Python) | `cursor/telegram-bot-fa-a10e` | Yes — only needs a bot token + internet |
| Azure DevOps (TFS) sprint task scripts (Python/PowerShell) | `cursor/tfs-sprint-task-automation-9ce5` | No — targets corporate `https://azure.okco.ir` + PAT |
| MSSQL HA MCP config | `cursor/mssql-ha-mcp-windows-auth-5f35` | No — targets corporate SQL Server + Windows/NTLM domain auth |
| GitHub migration scripts | `cursor/migrate-to-mfarhangian-9ce5` | Do not run — force-pushes branches to external repos (destructive) |

Because `main` has no `requirements.txt`, the startup update script is a **no-op on `main`**
and only installs dependencies when the checked-out branch has a root `requirements.txt`
(i.e. the Telegram bot branch).

### Telegram forward-bot (primary runnable product)

Persian Telegram bot: forwards any user message (with sender info) to an admin, and lets the
admin reply by using Telegram "Reply" on the forwarded message. Long-polling via
`python-telegram-bot`; state is a local `.reply_map.json` (auto-created). No database.

- Install / run commands: see the branch's `README.md` and `requirements.txt`
  (`pip install -r requirements.txt`, then `python -m bot.main`).
- Required to actually run: env var `TELEGRAM_BOT_TOKEN` (from `@BotFather`).
  `ADMIN_USERNAME` / `ADMIN_CHAT_ID` default to the repo owner's values in `bot/config.py`.
  On filtered networks set `TELEGRAM_PROXY` (HTTP or SOCKS5).
- Verifying without a real token: `python -m bot.main` with a dummy token will reach
  Telegram and fail fast with `InvalidToken: Unauthorized` (HTTP 401). A 401 (not a timeout)
  confirms deps + egress to `api.telegram.org` are working; only the token is missing.
- The bot enforces a single instance via a `.bot.lock` file (PID-based). If startup reports
  "already running", remove a stale `.bot.lock` at the repo root.

### Gotchas

- Ubuntu 24.04 Python is PEP 668 "externally managed". Global installs need
  `pip install --break-system-packages ...` (what the update script uses), or create a
  virtualenv (requires the `python3.12-venv` apt package, which is a system dependency and
  is intentionally not in the update script).
- To run a product branch while keeping `main` checked out, use a git worktree, e.g.
  `git worktree add ../telegram origin/cursor/telegram-bot-fa-a10e`.
