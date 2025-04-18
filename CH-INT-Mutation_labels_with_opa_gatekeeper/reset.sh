#!/bin/bash
set -e

echo "🧹 Cleaning up the lab environment..."

kubectl -n team-purple delete assign.mutations.gatekeeper.sh add-seccomp-profile-in-pods-team-purple > /dev/null 2>&1
kubectl -n team-blue delete assignmetadata.mutations.gatekeeper.sh mutation-label-admin-blue > /dev/null 2>&1
kubectl delete ns team-blue --ignore-not-found --force > /dev/null 2>&1
kubectl delete ns team-green --ignore-not-found --force > /dev/null 2>&1
kubectl delete ns team-purple --ignore-not-found --force > /dev/null 2>&1
kubectl delete ns gatekeeper-system --ignore-not-found --force > /dev/null 2>&1
echo "✅ Cleanup complete."
