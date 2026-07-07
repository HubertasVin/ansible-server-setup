#!/usr/bin/env bash
# filepath: back-end/k8s/deploy.sh
# Applies the kustomized manifests in this directory to the current k3s context.
# Run this ON the vps (after `ssh vps`), not from your local machine.
#
# Usage:
#   cd ~/apps/detourpilot/k8s
#   ./deploy.sh
#
# Optional env vars:
#   NAMESPACE  - target namespace (default: detourpilot)
#   DEPLOYMENT - deployment to restart (default: back-end)
#   TIMEOUT    - rollout timeout in seconds (default: 120)
set -euo pipefail

NAMESPACE="${NAMESPACE:-detourpilot}"
DEPLOYMENT="${DEPLOYMENT:-back-end}"
TIMEOUT="${TIMEOUT:-120}"

# Make sure we're actually talking to a cluster.
if ! kubectl cluster-info >/dev/null 2>&1; then
  echo "✗ kubectl can't reach a cluster. Check KUBECONFIG / kubeconfig path." >&2
  exit 1
fi

CONTEXT="$(kubectl config current-context)"
echo "→ Applying manifests (context: $CONTEXT, namespace: $NAMESPACE)"
kubectl apply -k .

echo "→ Restarting deployment/$DEPLOYMENT"
kubectl rollout restart "deployment/$DEPLOYMENT" -n "$NAMESPACE"

echo "✓ Watching rollout (timeout: ${TIMEOUT}s):"
kubectl rollout status "deployment/$DEPLOYMENT" -n "$NAMESPACE" --timeout="${TIMEOUT}s"