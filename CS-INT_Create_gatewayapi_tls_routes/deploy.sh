#!/bin/bash
set -e

echo "🔧 Creating lab resources ..."
kubectl apply -f manifests/ > /dev/null

echo "🔍 Installing Gateway API support ..."
bash tools/install-gateway-api.sh > /dev/null

echo
echo "************************************"
echo
cat README.txt
echo
