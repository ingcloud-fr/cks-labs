#!/bin/bash
set -e

echo "🔧 Creating namespaces..."
kubectl apply -f manifests/namespaces.yaml > /dev/null

sudo cp /etc/containerd/config.toml /etc/containerd/config.toml.SAVE

echo 
echo "************************************"
echo
cat README.txt
echo