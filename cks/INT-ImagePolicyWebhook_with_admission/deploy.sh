#!/bin/bash
set -e

echo "🔧 Creating lab resources ..."

# Create directory for webhook configs
sudo mkdir -p /etc/kubernetes/security/webhook

# Save kube-apiserver manifest (good practice)
sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/kube-apiserver.yaml

# Create Namespace for webhook
kubectl create namespace webhook-system

# -----------------------------------------
# Generate CA and server cert for webhook
# -----------------------------------------

# Generate a private CA (mini CA just for the webhook)
openssl genrsa -out /tmp/webhook-ca.key 2048
openssl req -x509 -new -nodes -key /tmp/webhook-ca.key -subj "/CN=webhook-ca.webhook-system.svc" -days 365 -out /tmp/webhook-ca.crt

# Generate webhook server key
openssl genrsa -out /tmp/tls-webhook.key 2048

# Create CSR (Certificate Signing Request) for the webhook server
openssl req -new -key /tmp/tls-webhook.key \
  -subj "/CN=webhook-service.webhook-system.svc" \
  -addext "subjectAltName=DNS:webhook-service.webhook-system.svc" \
  -out /tmp/tls-webhook.csr

# Sign the server certificate with our mini CA
openssl x509 -req -in /tmp/tls-webhook.csr -CA /tmp/webhook-ca.crt -CAkey /tmp/webhook-ca.key -CAcreateserial \
  -out /tmp/tls-webhook.crt -days 365 -extensions v3_req -extfile <(printf "[v3_req]\nsubjectAltName=DNS:webhook-service.webhook-system.svc")

# -----------------------------------------
# Deploy Webhook server
# -----------------------------------------

# Create secret for webhook server certs
kubectl delete secret webhook-server-tls --namespace webhook-system --ignore-not-found
kubectl create secret tls webhook-server-tls \
  --cert=/tmp/tls-webhook.crt \
  --key=/tmp/tls-webhook.key \
  --namespace=webhook-system

# Apply Deployment and Service manifests
kubectl apply -f manifests/

# -----------------------------------------
# Patch /etc/hosts for control-plane DNS resolution
# -----------------------------------------

echo "⏳ Waiting for webhook-service to be assigned an IP..."
kubectl wait --namespace webhook-system --for=jsonpath='{.spec.clusterIP}' --timeout=20s service/webhook-service

WEBHOOK_SERVICE_IP=$(kubectl get svc webhook-service -n webhook-system -o jsonpath='{.spec.clusterIP}')

if ! grep -q "webhook-service.webhook-system.svc" /etc/hosts; then
  echo "$WEBHOOK_SERVICE_IP webhook-service.webhook-system.svc" | sudo tee -a /etc/hosts
fi

# -----------------------------------------
# Create kubeconfig for ImagePolicyWebhook
# -----------------------------------------

# Build kubeconfig pointing to the webhook server
sudo kubectl config set-cluster webhook-server \
  --certificate-authority=/tmp/webhook-ca.crt \
  --server=https://webhook-service.webhook-system.svc/validate \
  --kubeconfig=/etc/kubernetes/security/webhook/webhook-kubeconfig.yaml \
  --embed-certs=true

sudo kubectl config set-credentials webhook-user \
  --client-certificate=/tmp/tls-webhook.crt \
  --client-key=/tmp/tls-webhook.key \
  --embed-certs=true \
  --kubeconfig=/etc/kubernetes/security/webhook/webhook-kubeconfig.yaml

sudo kubectl config set-context default \
  --cluster=webhook-server \
  --user=webhook-user \
  --kubeconfig=/etc/kubernetes/security/webhook/webhook-kubeconfig.yaml

sudo kubectl config use-context default \
  --kubeconfig=/etc/kubernetes/security/webhook/webhook-kubeconfig.yaml

echo
echo "************************************"
echo
cat README.txt
echo
