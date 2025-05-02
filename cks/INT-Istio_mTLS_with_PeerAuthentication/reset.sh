#!/bin/bash
set -e

echo "🧹 Deleting application namespace..."
kubectl -n team-app delete peerauthentications.security.istio.io mutual-tls-auth --ignore-not-found=true > /dev/null 2>&1
kubectl delete namespace team-app --ignore-not-found=true >/dev/null
kubectl delete -f manifests/ --ignore-not-found=true > /dev/null 2>&1

rm -rf ~/manifests > /dev/null


echo "🗑️ Deleting Istio Helm releases..."
helm uninstall istio-ingress -n istio-system >/dev/null 2>&1 || true
helm uninstall istiod -n istio-system >/dev/null 2>&1 || true
helm uninstall istio-base -n istio-system >/dev/null 2>&1 || true

echo "🧽 Deleting istio-system namespace..."
kubectl delete namespace istio-system --ignore-not-found=true >/dev/null

echo "✅ Reset complete."