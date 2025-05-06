#!/bin/bash
set -e

echo "🧹 Cleaning up the lab..."

# Delete resources using manifest files
kubectl delete -f manifests/ --ignore-not-found=true > /dev/null 2>&1

[ -f /tmp/kube-apiserver.yaml.SAVE ] && sudo mv /tmp/kube-apiserver.yaml.SAVE /etc/kubernetes/manifests/kube-apiserver.yaml

echo "✅ Reset complete."