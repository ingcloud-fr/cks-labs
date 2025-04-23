#!/bin/bash
set -e

echo "🔧 Creating lab resources ..."
kubectl apply -f manifests/ > /dev/null

mkdir ~/manifests
cp manifests/02-nginx.yaml ~/manifests/nginx.yaml

echo
echo "************************************"
echo
cat README.txt
echo