#!/bin/bash

USER_HOME="/home/insert-user-name-here"
GITHUB_TOKEN="replace-with-github-token"
REPO_URL="https://${GITHUB_TOKEN}@github.com/HubertasVin/obsidian-sync.git"

exec 2>$USER_HOME/sync-data.log
cd $USER_HOME/dav_data/Obsidian\ Vault || exit 1

# Mark the directory as safe for Git
git config --global --add safe.directory $USER_HOME/dav_data/Obsidian\ Vault

# Add, commit, and push any new or changed files
git add -A
if ! git diff --cached --quiet; then
    git commit -m "Daily sync $(date +'%Y-%m-%d %H:%M:%S')"
    git push "$REPO_URL" "$(git branch --show-current)" >> $USER_HOME/sync-data.log 2>&1
fi
