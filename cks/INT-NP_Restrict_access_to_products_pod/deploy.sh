#!/bin/bash
set -e

echo "🔧 Creating lab resources ..."
kubectl apply -f manifests/ > /dev/null

echo
echo "************************************"
echo
cat README.txt
echo