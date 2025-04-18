#!/bin/bash
set -e

echo "🔧 Creating namespaces ..."
kubectl apply -f manifests/namespaces.yaml > /dev/null

echo
echo "************************************"
echo
cat README.txt
echo
