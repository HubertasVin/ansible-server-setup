#!/bin/bash
cd /home/hubserv/dav_data/Obsidian Vault || exit 1

# Add, commit, and push any new or changed files
git add -A
if ! git diff --cached --quiet; then
    git commit -m "Daily sync $(date +'%Y-%m-%d %H:%M:%S')"
    git push
fi
