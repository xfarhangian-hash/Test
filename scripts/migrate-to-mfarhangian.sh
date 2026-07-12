#!/usr/bin/env bash
set -euo pipefail

# Migrate all project branches from xfarhangian-hash/Test to MFarhangian GitHub account.
# Requires a Personal Access Token for https://github.com/MFarhangian
#
# Usage:
#   export GITHUB_TOKEN='ghp_...'
#   ./scripts/migrate-to-mfarhangian.sh

OWNER="MFarhangian"
SOURCE_REPO="https://github.com/xfarhangian-hash/Test.git"
WORKDIR="${WORKDIR:-/tmp/mfarhangian-migration}"

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  echo "Set GITHUB_TOKEN to a PAT for the MFarhangian account." >&2
  exit 1
fi

auth_user="$(curl -fsSL -H "Authorization: Bearer ${GITHUB_TOKEN}" https://api.github.com/user | python3 -c 'import json,sys; print(json.load(sys.stdin).get("login",""))')"
if [[ "${auth_user}" != "${OWNER}" ]]; then
  echo "GITHUB_TOKEN belongs to '${auth_user}', expected '${OWNER}'." >&2
  exit 1
fi

api() {
  local method="$1"
  local path="$2"
  shift 2
  curl -fsSL -X "${method}" \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com${path}" "$@"
}

ensure_repo() {
  local name="$1"
  local description="$2"
  if api GET "/repos/${OWNER}/${name}" >/dev/null 2>&1; then
    echo "Repo ${OWNER}/${name} already exists."
  else
    echo "Creating ${OWNER}/${name}..."
    api POST "/user/repos" \
      -d "{\"name\":\"${name}\",\"description\":\"${description}\",\"private\":false}"
  fi
}

push_branch() {
  local local_ref="$1"
  local remote_url="$2"
  local remote_ref="$3"
  git push "https://x-access-token:${GITHUB_TOKEN}@github.com/${OWNER}/${remote_url}.git" \
    "${local_ref}:${remote_ref}" --force
}

rm -rf "${WORKDIR}"
mkdir -p "${WORKDIR}"
git clone "${SOURCE_REPO}" "${WORKDIR}/source"

echo "==> Migrating TFS sprint automation"
ensure_repo "TFS-Sprint-Automation" "Azure DevOps sprint task automation for recurring backlog items"
push -d "${WORKDIR}/source" >/dev/null
git checkout cursor/tfs-sprint-task-automation-9ce5
popd >/dev/null
push_branch "cursor/tfs-sprint-task-automation-9ce5:refs/heads/main" "TFS-Sprint-Automation" "main"

echo "==> Migrating Telegram bot"
ensure_repo "Telegram" "Telegram bot for forwarding messages to admin"
push -d "${WORKDIR}/source" >/dev/null
git checkout cursor/telegram-bot-fa-a10e
popd >/dev/null
push_branch "cursor/telegram-bot-fa-a10e:refs/heads/main" "Telegram" "main"

echo ""
echo "Migration complete:"
echo "  https://github.com/${OWNER}/TFS-Sprint-Automation"
echo "  https://github.com/${OWNER}/Telegram"
