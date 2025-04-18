#!/bin/bash
set -e

echo "🧹 Nettoyage du lab..."

# Suppression des ressources utilisateur
kubectl delete -f manifests/ --ignore-not-found=true

# Suppression du secret TLS
kubectl delete secret secret-tls -n team-web --ignore-not-found=true

# Suppression des objets Gateway et HTTPRoute
kubectl delete gateway my-gateway -n team-web --ignore-not-found=true
kubectl delete httproute pay-shop-route -n team-web --ignore-not-found=true

# Suppression de la GatewayClass
kubectl delete gatewayclass nginx --ignore-not-found=true

# Désinstallation de NGINX Gateway Fabric via Helm
helm uninstall ngf -n nginx-gateway || true

# Suppression du namespace nginx-gateway
kubectl delete namespace nginx-gateway --ignore-not-found=true

# Suppression des CRDs Gateway API
kubectl kustomize "https://github.com/nginx/nginx-gateway-fabric/config/crd/gateway-api/standard?ref=v1.6.2" | kubectl delete -f -

echo "✅ Réinitialisation terminée."
