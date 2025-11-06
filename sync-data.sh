#!/bin/bash

USER_HOME="/home/insert-user-name-here"
GITHUB_TOKEN="replace-with-github-token"
REPO_URL="https://backupuser:${GITHUB_TOKEN}@github.com/HubertasVin/obsidian-sync.git"
VAULT_DIR="$USER_HOME/dav_data/Obsidian Vault"
exec >$USER_HOME/sync-data.log 2>&1

if [ "$GITHUB_TOKEN" = "replace-with-github-token" ]; then
    echo "Error: GITHUB_TOKEN is not set. Aborting." >&2
    exit 1
fi

TEMP_DIR=$(mktemp -d -p "$USER_HOME" git-sync-XXXXXX)

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo "Cloning repository..."
git clone "$REPO_URL" "$TEMP_DIR"
cd "$TEMP_DIR" || exit 1

git config user.email "backup@local"
git config user.name "Backup User"
git config --global init.defaultBranch main

echo "Syncing vault contents..."
rsync -av --delete --exclude='.git' "$VAULT_DIR/" "$TEMP_DIR/" || exit 1

if git diff --quiet && git diff --cached --quiet; then
    echo "No changes to commit" || exit 0
fi

git add -A
git commit -m "Daily sync $(date +'%Y-%m-%d %H:%M:%S')"

git pull --rebase origin main 2>&1 || {
    echo "Pull failed, attempting to resolve..."
    git rebase --abort 2>/dev/null
    git pull --no-rebase --strategy=ours origin main 2>&1
}

git push origin main 2>&1 || {
    echo "Push failed, retrying with pull first..."
    git pull --rebase origin main
    git push origin main 2>&1
}

echo "$(date): Sync completed successfully"

tmpdir=$(mktemp -d -p "$USER_HOME" proton-os-sync-XXXXXX)
zipname="backup-$(date +'%Y-%m-%d_%H:%M:%S').zip"
trap 'rm -rf "$tmpdir"' EXIT

cd "$VAULT_DIR" || exit 1
zip $tmpdir/$zipname *

rclone copy $tmpdir/$zipname ProtonDrive:Obsidian\ backups/
