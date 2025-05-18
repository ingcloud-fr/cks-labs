#!/bin/bash
set -e

echo "🔧 Creating lab resources ..."
kubectl apply -f manifests/ > /dev/null
# Supprime toutes les CiliumClusterwideNetworkPolicies
kubectl delete ciliumnetworkpolicy --all --ignore-not-found
echo
echo "************************************"
echo
cat README.txt
echo