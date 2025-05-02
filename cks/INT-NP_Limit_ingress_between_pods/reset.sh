#!/bin/bash
set -e

echo "🧹 Cleaning up the lab..."


kubectl -n team-green delete networkpolicies ingress-allow-backend --ignore-not-found=true > /dev/null 2>&1
kubectl -n team-green delete networkpolicies ingress-deny --ignore-not-found=true > /dev/null 2>&1

# Delete resources using manifest files
kubectl delete -f manifests/ --ignore-not-found=true > /dev/null 2>&1

echo "✅ Reset complete."