#!/bin/bash
set -e

echo "🧹 Cleaning up Janice's user lab..."

kubectl delete -f manifests/ --ignore-not-found=true
kubectl delete csr janice-csr --ignore-not-found=true
kubectl delete ns janice-space --ignore-not-found=true

rm -f janice.key janice.csr janice.crt janice.kubeconfig

echo "✅ Reset complete."
