#!/bin/bash
set -e

echo "🧹 Cleaning up the lab..."

# Delete resources using manifest files
kubectl delete -f manifests/ --ignore-not-found=true # > /dev/null 2>&1
# Remove label from node01 (found dynamically)
NODE01_FULL=$(kubectl get nodes -o name | grep node01 | cut -d'/' -f2)
kubectl label node "$NODE01_FULL" node- > /dev/null 2>&1 || true

echo "✅ Reset complete."