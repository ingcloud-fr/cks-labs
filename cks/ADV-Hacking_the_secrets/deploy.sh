#!/bin/bash
set -e

echo "🔧 Creating lab resources ..."
kubectl apply -f manifests/ > /dev/null

echo "🔐 Configuring restricted user context ..."
bash tools/configure-context.sh > /dev/null

echo
echo "************************************"
echo
cat README.txt
echo
