#!/bin/bash
set -e

echo "🧹 Cleaning up lab resources..."

kubectl delete -f manifests/app-a.yaml --force --ignore-not-found > /dev/null
kubectl delete -f manifests/app-b.yaml --force --ignore-not-found > /dev/null
kubectl delete -f manifests/app-c.yaml --force --ignore-not-found > /dev/null

# kubectl delete -f manifests/ns-team-red.yaml --ignore-not-found > /dev/null
# kubectl delete -f manifests/ns-team-green.yaml --ignore-not-found > /dev/null
# kubectl delete -f manifests/ns-team-blue.yaml --ignore-not-found > /dev/null

echo "🧼 Uninstalling Tracee..."
helm uninstall tracee -n tracee-system || true > /dev/null
kubectl delete ns tracee-system --ignore-not-found > /dev/null

echo "✅ Reset finished."
