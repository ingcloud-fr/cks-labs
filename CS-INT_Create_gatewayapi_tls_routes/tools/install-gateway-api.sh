#!/bin/bash
set -e

# Docs : docs.nginx.com/nginx-gateway-fabric/installation/installing-ngf/helm

echo "📦 Installation des CRDs Gateway API..."
kubectl kustomize "https://github.com/nginx/nginx-gateway-fabric/config/crd/gateway-api/standard?ref=v1.6.2" | kubectl apply -f -

echo "🚀 Déploiement de NGINX Gateway Fabric via Helm (OCI)..."
# $ helm show values oci://ghcr.io/nginx/charts/nginx-gateway-fabric
# Pas de création d'un gatewayClass avec gatewayClass.create=false
helm install ngf oci://ghcr.io/nginx/charts/nginx-gateway-fabric \
  --create-namespace \
  -n nginx-gateway \
  --set service.type=NodePort > /dev/null

echo "⏳ Attente de la disponibilité du déploiement..."
kubectl wait --timeout=5m -n nginx-gateway deployment/ngf-nginx-gateway-fabric --for=condition=Available

echo "✅ Installation terminée."
