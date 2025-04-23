#!/bin/bash
set -e

echo "📦 Installing ingress-nginx controller..."

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx > /dev/null
helm repo update > /dev/null

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.ingressClassResource.name=nginx \
  --set controller.ingressClassResource.controllerValue=k8s.io/ingress-nginx \
  --set controller.ingressClass=nginx \
  --set controller.service.type=NodePort > /dev/null

echo "⏳ Waiting for ingress controller pod to be Ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=Ready pod \
  -l app.kubernetes.io/component=controller \
  --timeout=180s

echo "✅ Ingress NGINX controller installed."
