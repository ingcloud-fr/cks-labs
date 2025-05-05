#!/bin/bash
set -e

echo "🧹 Cleaning up lab resources ..."

# Delete the webhook namespace (this will remove all resources inside)
kubectl delete namespace webhook-system --ignore-not-found=true > /dev/null

# Clean /etc/hosts entry for webhook-service
if grep -q "webhook-service.webhook-system.svc" /etc/hosts; then
  echo "✔️ Cleaning /etc/hosts entry..."
  sudo sed -i '/webhook-service.webhook-system.svc/d' /etc/hosts
fi

# Delete the /etc/kubernetes/security/webhook directory if it exists
if [ -d /etc/kubernetes/security/webhook ]; then
  sudo rm -rf /etc/kubernetes/security/webhook
  echo "✔️ Deleted webhook kubeconfig and certificates."
fi

# Restore the original kube-apiserver manifest if it was backed up
if [ -f /tmp/kube-apiserver.yaml ]; then
  sudo cp /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/kube-apiserver.yaml
  echo "✔️ Restored kube-apiserver manifest."
fi

echo "✅ Lab cleanup completed."
