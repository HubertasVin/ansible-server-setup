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
#   NAMESPACE            - app namespace (default: detourpilot)
#   DEPLOYMENT           - app deployment to restart (default: back-end)
#   INGRESS_NAMESPACE    - ingress-nginx namespace (default: ingress-nginx)
#   INGRESS_DEPLOYMENT   - ingress controller deployment (default: ingress-nginx-controller)
#   TIMEOUT              - rollout timeout in seconds (default: 120)
set -euo pipefail

NAMESPACE="${NAMESPACE:-detourpilot}"
DEPLOYMENT="${DEPLOYMENT:-back-end}"
INGRESS_NAMESPACE="${INGRESS_NAMESPACE:-ingress-nginx}"
INGRESS_DEPLOYMENT="${INGRESS_DEPLOYMENT:-ingress-nginx-controller}"
TIMEOUT="${TIMEOUT:-120}"

# Make sure we're actually talking to a cluster.
if ! kubectl cluster-info >/dev/null 2>&1; then
  echo "✗ kubectl can't reach a cluster. Check KUBECONFIG / kubeconfig path." >&2
  exit 1
fi

CONTEXT="$(kubectl config current-context)"
echo "→ Applying manifests (context: $CONTEXT, namespace: $NAMESPACE)"
kubectl apply -k .

echo "→ Restarting deployment/$DEPLOYMENT (in $NAMESPACE)"
kubectl rollout restart "deployment/$DEPLOYMENT" -n "$NAMESPACE"

# The ingress-nginx controller's RBAC and pod spec can change between
# releases; 'kubectl apply' does not always pick up the diff (e.g. when
# a ClusterRole only adds a verb), so always force a rollout here.
echo "→ Restarting deployment/$INGRESS_DEPLOYMENT (in $INGRESS_NAMESPACE)"
kubectl rollout restart "deployment/$INGRESS_DEPLOYMENT" -n "$INGRESS_NAMESPACE"

echo "✓ Watching rollout (timeout: ${TIMEOUT}s):"
kubectl rollout status "deployment/$DEPLOYMENT" -n "$NAMESPACE" --timeout="${TIMEOUT}s"
kubectl rollout status "deployment/$INGRESS_DEPLOYMENT" -n "$INGRESS_NAMESPACE" --timeout="${TIMEOUT}s"