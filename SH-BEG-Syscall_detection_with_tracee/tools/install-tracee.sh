#!/bin/bash
set -e

echo "📦 Installation de Tracee via Helm..."

helm repo add aqua https://aquasecurity.github.io/helm-charts/
helm repo update
helm install tracee aqua/tracee \
        --namespace tracee-system --create-namespace \
        --set hostPID=true

echo "✅ Tracee installé dans le namespace tracee-system"
