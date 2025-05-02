#!/bin/bash
set -e

echo "🧹 Cleaning up the lab..."


kubectl -n team-orange delete networkpolicies allow-across-team --ignore-not-found=true # > /dev/null 2>&1
# Delete resources using manifest files
kubectl delete -f manifests/ --ignore-not-found=true # > /dev/null 2>&1

echo "✅ Reset complete."