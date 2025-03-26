#!/bin/bash

USER_HOME="/home/insert-user-name-here"
GITHUB_TOKEN="replace-with-github-token"
REPO_URL="https://backupuser:${GITHUB_TOKEN}@github.com/HubertasVin/obsidian-sync.git"

if [ "$GITHUB_TOKEN" = "replace-with-github-token" ]; then
    echo "Error: GITHUB_TOKEN is not set. Aborting." >&2
    exit 1
fi

exec 2>$USER_HOME/sync-data.log
cd $USER_HOME/dav_data/Obsidian\ Vault || exit 1

# Initialize git repository if not already initialized
if [ ! -d ".git" ]; then
    git init
    git branch -m master main >> /dev/null 2>&1
    git remote add origin "$REPO_URL"
    git config --global init.defaultBranch main
fi

# Mark the directory as safe for Git
git config --global --add safe.directory $USER_HOME/dav_data/Obsidian\ Vault

# Add, commit, and push any new or changed files
git add -A
if ! git diff --cached --quiet; then
    git commit -m "Daily sync $(date +'%Y-%m-%d %H:%M:%S')"
fi
git pull --rebase origin "$(git branch --show-current)" 2>&1
git push -u origin "$(git branch --show-current)" 2>&1
