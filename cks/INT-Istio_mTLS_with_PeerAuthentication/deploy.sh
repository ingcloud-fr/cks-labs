#!/bin/bash
set -e

echo "🔧 Creating application namespace and enabling sidecar injection..."
kubectl create namespace team-app >/dev/null
#kubectl label namespace team-app istio-injection=enabled --overwrite

echo "📦 Adding Istio Helm repository..."
helm repo add istio https://istio-release.storage.googleapis.com/charts >/dev/null
helm repo update >/dev/null

echo "🧱 Installing Istio Base (CRDs)..."
helm upgrade --install istio-base istio/base -n istio-system --set defaultRevision=default --create-namespace --wait >/dev/null

echo "🧠 Installing Istiod (control plane)..."
helm upgrade --install istiod istio/istiod -n istio-system --wait >/dev/null

# echo "🌐 Installing Istio Ingress Gateway..."
# helm upgrade --install istio-ingress istio/gateway -n istio-system --wait >/dev/null

echo "🚀 Deploying application manifests..."
kubectl apply -f manifests/ >/dev/null

mkdir -p ~/manifests
cp manifests/01-httpbin.yaml ~/manifests/httpbin.yaml
cp manifests/02-client.yaml ~/manifests/client.yaml
cp manifests/03-naked.yaml ~/manifests/naked.yaml

echo
echo "************************************"
echo
cat README.txt
echo
