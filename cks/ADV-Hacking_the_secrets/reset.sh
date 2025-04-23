#!/bin/bash
set -e

echo "🧹 Cleaning up the lab..."

# Delete resources using manifest files
kubectl delete -f manifests/ --ignore-not-found=true # > /dev/null 2>&1

# Delete kubeconfig context and user
kubectl config use-context kubernetes-admin@kubernetes
kubectl config delete-context restricted@infra-prod # > /dev/null 2>&1 || true
kubectl config delete-user restricted-user # > /dev/null 2>&1 || true

# Restore ~/.kube/config (just in case ...)
rm  ~/.kube/config
mv ~/.kube/config.SAVE ~/.kube/config

echo "✅ Reset complete."