#!/bin/bash

set -euo pipefail

USER_HOME="/home/insert-user-name-here"
GITHUB_TOKEN="replace-with-github-token"
GITCRYPT_KEY_B64="replace-with-gitcrypt-key-b64"
REPO_URL="https://backupuser:${GITHUB_TOKEN}@github.com/HubertasVin/obsidian-sync.git"

if [ "$GITHUB_TOKEN" = "replace-with-github-token" ]; then
    echo "Error: GITHUB_TOKEN is not set. Aborting." >&2
    exit 1
fi

exec 2>"$USER_HOME/sync-data.log"
mkdir -p "$USER_HOME/dav_data/Obsidian Vault" && cd "$USER_HOME/dav_data/Obsidian Vault" || exit 1

# Initialize git repository if not already initialized
if [ ! -d ".git" ]; then
    tmprepo="$(mktemp -d)"
    git clone --no-checkout "$REPO_URL" "$tmprepo"
    mv "$tmprepo/.git" ".git"
    rm -rf "$tmprepo"

    branch="$(git remote show origin 2>/dev/null | awk '/HEAD branch/ {print $NF}')"
    branch="${branch:-main}"

    # unlock BEFORE first checkout so smudge yields plaintext
    if command -v git-crypt >/dev/null 2>&1 && [ "${GITCRYPT_KEY_B64}" != "replace-with-gitcrypt-key-b64" ] && [ -n "${GITCRYPT_KEY_B64}" ]; then
        tmpkey="$(mktemp)"; trap 'rm -f "$tmpkey"' EXIT
        printf %s "${GITCRYPT_KEY_B64}" | base64 -d > "$tmpkey"
        git-crypt unlock "$tmpkey" || true
    fi

    git fetch origin
    git checkout -B "$branch" "origin/$branch"
    git reset --hard "origin/$branch"
fi

# safe dir for root
git config --global --add safe.directory "$PWD" || true

# unlock every run
if command -v git-crypt >/dev/null 2>&1 && [ "${GITCRYPT_KEY_B64}" != "replace-with-gitcrypt-key-b64" ] && [ -n "${GITCRYPT_KEY_B64}" ]; then
    tmpkey2="$(mktemp)"; trap 'rm -f "$tmpkey2"' RETURN
    printf %s "${GITCRYPT_KEY_B64}" | base64 -d > "$tmpkey2"
    git-crypt unlock "$tmpkey2" || true
fi

# stage + commit local edits
git add -A
git commit -m "Daily sync $(date +'%Y-%m-%d %H:%M:%S')" || true

# pull (rebasing) then push
branch="$(git symbolic-ref --quiet --short HEAD || echo main)"
git fetch origin "$branch" || true
if ! git pull --rebase --autostash origin "$branch"; then
    git rebase --abort || true
    git merge -s ours --no-edit "origin/$branch" || true
fi
git push -u origin "$branch" || true
