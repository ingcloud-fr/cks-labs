#!/bin/bash
set -e

echo "🧹 Cleaning up the lab..."

kubectl delete -f manifests/ --ignore-not-found=true # > /dev/null 2>&1
kubectl -n team-green delete networkpolicies allow-same-namespace-only # > /dev/null 2>&1
kubectl -n team-blue delete networkpolicies allow-same-namespace-only # > /dev/null 2>&1
kubectl -n team-red delete networkpolicies allow-same-namespace-only # > /dev/null 2>&1
kubectl delete ns team-blue team-green team-red --ignore-not-found=true #  > /dev/null 2>&1

echo "✅ Reset complete."
