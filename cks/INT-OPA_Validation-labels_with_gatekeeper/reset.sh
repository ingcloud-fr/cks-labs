#!/bin/bash
set -e

echo "🧹 Cleaning up the lab environment..."

kubectl delete k8srequiredlabels.constraints.gatekeeper.sh pods-must-have-label-env --ignore-not-found > /dev/null 2>&1
kubectl delete constrainttemplate k8srequiredlabels --ignore-not-found > /dev/null 2>&1
kubectl delete manifests/ --ignore-not-found --force > /dev/null 2>&1

echo "✅ Cleanup complete."
