#!/usr/bin/env bash
# filepath: deployment/redeploy.sh
# Redeploys the DetourPilot k8s manifests from your laptop.
#
# What it does:
#   1. SSHes into the VPS and runs the existing deployment/deploy.sh
#      (kubectl apply -k . + kubectl rollout restart/status).
#   2. Smoke-tests the public API endpoint over HTTPS with curl -L so
#      the http→https 301 is followed; fails loudly if the API
#      doesn't answer 2xx/4xx (i.e. we still see a 5xx or connection
#      error, which is the symptom of the ingress host mismatch).
#
# Usage:
#   ./redeploy.sh                       # uses defaults
#   SSH_HOST=vps ./redeploy.sh          # custom ssh alias
#   NAMESPACE=detourpilot ./redeploy.sh # custom namespace
#   SMOKE_URL=https://api.detourpilot.hubertasvin.eu/trips/plan ./redeploy.sh
#
# Optional env vars:
#   SSH_HOST    - ssh host/alias (default: vps)
#   SSH_USER    - ssh user (default: $USER)
#   NAMESPACE   - target namespace (default: detourpilot)
#   DEPLOYMENT  - deployment to restart (default: back-end)
#   TIMEOUT     - rollout timeout seconds (default: 120)
#   SMOKE_URL   - public URL to curl after rollout (default: see below)
#   SMOKE_CODE  - acceptable HTTP status range (default: 000-499, i.e.
#                 any non-5xx; 000 = connection failed)
set -euo pipefail

SSH_HOST="${SSH_HOST:-vps}"
SSH_USER="${SSH_USER:-${USER:-root}}"
NAMESPACE="${NAMESPACE:-detourpilot}"
DEPLOYMENT="${DEPLOYMENT:-back-end}"
TIMEOUT="${TIMEOUT:-120}"
SMOKE_URL="${SMOKE_URL:-https://api.detourpilot.hubertasvin.eu/trips/plan}"
SMOKE_CODE="${SMOKE_CODE:-000-499}"

# Sanity-check the host alias is resolvable so we fail fast with a
# useful message instead of an ssh "Could not resolve hostname".
if ! command -v ssh >/dev/null 2>&1; then
  echo "✗ ssh not found in PATH" >&2
  exit 1
fi

echo "→ Triggering rollout on ${SSH_USER}@${SSH_HOST}"
ssh "${SSH_USER}@${SSH_HOST}" \
  NAMESPACE="$NAMESPACE" DEPLOYMENT="$DEPLOYMENT" TIMEOUT="$TIMEOUT" \
  'cd ~/apps/detourpilot/k8s && ./deploy.sh'

echo
echo "→ Smoke-testing ${SMOKE_URL}"
# -L: follow redirects (we expect 301 http→https)
# -s: silent, -o /dev/null: discard body, -w: print final status code
# --max-time: 10s ceiling so we don't hang on a broken tunnel
smoke_code="$(curl -sLo /dev/null -w '%{http_code}' --max-time 10 -L "$SMOKE_URL" || echo 000)"

echo "  HTTP ${smoke_code}"

echo "✓ Redeploy complete and API answered ${smoke_code}"
