#!/bin/bash
set -e

echo "🔧 Creating lab resources ..."

# Apply manifests
kubectl apply -f manifests/ > /dev/null

# récupérer dynamiquement l'IP du service
WEBHOOK_SERVICE_IP=$(kubectl get svc webhook-service -n webhook-system -o jsonpath='{.spec.clusterIP}')

# Sauvegarder le kube-apiserver manifest avant modification
sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/kube-apiserver.yaml

# Generate TLS certs
openssl req -newkey rsa:2048 -nodes -keyout /tmp/tls-webhook.key \
  -x509 -days 365 -out /tmp/tls-webhook.crt \
  -subj "/CN=webhook-service.webhook-system.svc" \
  -addext "subjectAltName=DNS:webhook-service.webhook-system.svc" \
  -addext "subjectAltName=IP:${SERVICE_IP}" > /dev/null

# Create TLS secret
kubectl create secret tls webhook-server-tls \
  --cert=/tmp/tls-webhook.crt \
  --key=/tmp/tls-webhook.key \
  --namespace=webhook-system > /dev/null

# Generate kubeconfig for ImagePolicyWebhook
sudo mkdir -p /etc/kubernetes/security/webhook

sudo kubectl config set-cluster webhook-server \
  --certificate-authority=tls-webhook.crt \
  --server=https://${WEBHOOK_SERVICE_IP}/validate \
  --kubeconfig=/etc/kubernetes/security/webhook/webhook-kubeconfig.yaml \
  --embed-certs=true > /dev/null

sudo kubectl config set-credentials webhook-user \
  --client-key=tls-webhook.key \
  --client-certificate=tls-webhook.crt \
  --embed-certs=true \
  --kubeconfig=/etc/kubernetes/security/webhook/webhook-kubeconfig.yaml > /dev/null

sudo kubectl config set-context default \
  --cluster=webhook-server \
  --user=webhook-user \
  --kubeconfig=/etc/kubernetes/security/webhook/webhook-kubeconfig.yaml > /dev/null

sudo kubectl config use-context default \
  --kubeconfig=/etc/kubernetes/security/webhook/webhook-kubeconfig.yaml > /dev/null

echo
echo "************************************"
echo
cat README.txt
echo
