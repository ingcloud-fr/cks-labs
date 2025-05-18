#!/bin/bash
set -e

echo "🧹 Cleaning up the lab environment..."

kubectl delete k8srequiredlabels.constraints.gatekeeper.sh pods-must-have-label-env --ignore-not-found > /dev/null 
kubectl delete constrainttemplate k8srequiredlabels --ignore-not-found > /dev/null 
kubectl delete manifests/ --ignore-not-found > /dev/null 
kubectl delete ns gatekeeper-system --ignore-not-found > /dev/null 

echo "✅ Cleanup complete."
