#!/bin/bash
set -e


echo "🔧 Creating lab resources ..."
NODE01_FULL=$(kubectl get nodes -o name | grep node01 | cut -d'/' -f2)
kubectl label node "$NODE01_FULL" node=node01 --overwrite

echo "📦 Deploying workloads..."
kubectl apply -f manifests/ > /dev/null

echo "✅ Workloads deployed across nodes."

echo
echo "************************************"
echo
cat README.txt
echo
