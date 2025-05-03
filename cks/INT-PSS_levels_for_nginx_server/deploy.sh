#!/bin/bash
set -e

echo "🔧 Creating namespaces..."
kubectl apply -f manifests/namespaces.yaml > /dev/null

echo "🚀 Deploying applications..."
kubectl apply -f manifests/nginx-green.yaml > /dev/null
kubectl apply -f manifests/nginx-orange.yaml > /dev/null
kubectl apply -f manifests/nginx-red.yaml > /dev/null

mkdir -p ~/manifests
cp manifests/nginx-red.yaml ~/manifests
cp manifests/nginx-orange.yaml ~/manifests
cp manifests/nginx-green.yaml ~/manifests

echo 
echo "************************************"
echo
cat README.txt
echo
