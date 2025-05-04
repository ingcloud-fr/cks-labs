#!/bin/bash
set -e

echo "🔧 Creating lab resources ..."
kubectl apply -f manifests/ > /dev/null

echo "⏳ Waiting for pods to be ready..."
kubectl -n team-green rollout status deployment/nginx

echo "✅ Nginx deployment is ready. You can play !"

echo
echo "************************************"
echo
cat README.txt
echo