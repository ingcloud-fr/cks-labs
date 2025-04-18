#!/bin/bash
set -e

echo "🧹 Cleaning up the lab environment..."

kubectl delete k8srequiredlabels.constraints.gatekeeper.sh pods-must-have-label-env --ignore-not-found > /dev/null 2>&1
kubectl delete ns team-blue --ignore-not-found --force > /dev/null 2>&1
kubectl delete ns team-green --ignore-not-found --force > /dev/null 2>&1
kubectl delete ns gatekeeper-system --ignore-not-found --force > /dev/null 2>&1

echo "✅ Cleanup complete."
