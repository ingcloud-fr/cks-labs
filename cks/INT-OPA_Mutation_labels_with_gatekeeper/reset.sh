#!/bin/bash
set -e

echo "🧹 Cleaning up the lab environment..."

kubectl -n team-purple delete assign.mutations.gatekeeper.sh add-seccomp-profile-in-pods-team-purple --ignore-not-found  > /dev/null 2>&1
kubectl -n team-blue delete assignmetadata.mutations.gatekeeper.sh mutation-label-admin-blue --ignore-not-found  > /dev/null 2>&1
kubectl delete -f manifests/ --ignore-not-found > /dev/null 2>&1
kubectl delete ns gatekeeper-system --ignore-not-found > /dev/null

echo "✅ Cleanup complete."
