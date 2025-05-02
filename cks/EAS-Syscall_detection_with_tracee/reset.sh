#!/bin/bash
set -e

echo "🧼 Uninstalling Tracee..."
helm uninstall tracee -n tracee || true > /dev/null
kubectl delete ns tracee --ignore-not-found > /dev/null

echo "🧹 Cleaning up lab resources..."
kubectl delete -f manifests/

echo "✅ Reset finished."
