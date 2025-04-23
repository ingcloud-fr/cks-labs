#!/bin/bash
set -e

echo "🔧 Creating lab resources ..."
kubectl apply -f manifests/ > /dev/null
bash tools/install-ingress-nginx.sh
echo
echo "************************************"
echo
cat README.txt
echo