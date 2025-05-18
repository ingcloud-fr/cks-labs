#!/bin/bash
set -e

echo "🧹 Cleaning up the lab..."

# Delete resources using manifest files
kubectl delete -f manifests/ --ignore-not-found=true # > /dev/null 2>&1
# Supprime toutes les CiliumClusterwideNetworkPolicies
kubectl delete ciliumnetworkpolicy --all --ignore-not-found

echo "✅ Reset complete."