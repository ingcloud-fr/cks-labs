#!/bin/bash
set -e

echo "🧹 Cleaning up the lab..."

kubectl delete -f manifests/ --ignore-not-found=true > /dev/null
kubectl delete secret secret-tls -n team-web --ignore-not-found=true > /dev/null
helm uninstall ingress-nginx -n ingress-nginx --wait --ignore-not-found > /dev/null
kubectl delete namespace ingress-nginx --ignore-not-found=true > /dev/null

echo "✅ Reset complete."
