#!/bin/bash
set -e

echo "🔧 Creating lab resources ..."

# Creation directory for webhook
sudo mkdir -p /etc/kubernetes/security/webhook

# Create ns for webhook server
kubectl create ns webhook-system

# Generate TLS certs
openssl req -newkey rsa:2048 -nodes -keyout /tmp/tls-webhook.key \
  -x509 -days 365 -out /tmp/tls-webhook.crt \
  -subj "/CN=webhook-service.webhook-system.svc" \
  -addext "subjectAltName=DNS:webhook-service.webhook-system.svc" > /dev/null

# Create TLS secret
kubectl create secret tls webhook-server-tls \
  --cert=/tmp/tls-webhook.crt \
  --key=/tmp/tls-webhook.key \
  --namespace=webhook-system > /dev/null

# Apply manifests
kubectl apply -f manifests/ > /dev/null

echo "⏳ Waiting for webhook-service to be assigned an IP..."
kubectl wait --namespace webhook-system --for=jsonpath='{.spec.clusterIP}' --timeout=20s service/webhook-service

# Now it's safe to retrieve the IP
WEBHOOK_SERVICE_IP=$(kubectl get svc webhook-service -n webhook-system -o jsonpath='{.spec.clusterIP}')

# Only if the entry is not already present
if ! grep -q "webhook-service.webhook-system.svc" /etc/hosts; then
  echo "$WEBHOOK_SERVICE_IP webhook-service.webhook-system.svc" | sudo tee -a /etc/hosts
fi

# Sauvegarder le kube-apiserver manifest avant modification
sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/kube-apiserver.yaml



# Generate kubeconfig for ImagePolicyWebhook
sudo kubectl config set-cluster webhook-server \
  --certificate-authority=tls-webhook.crt \
  --server=https://webhook-service.webhook-system.svc/validate \
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
