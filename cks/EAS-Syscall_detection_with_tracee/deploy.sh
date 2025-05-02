#!/bin/bash
set -e

echo "🔧 Namespaces deployments ..."
kubectl apply -f manifests/ns-team-green.yaml > /dev/null
kubectl apply -f manifests/ns-team-red.yaml > /dev/null
kubectl apply -f manifests/ns-team-blue.yaml > /dev/null

echo "🚀 Installing applications..."
kubectl apply -f manifests/app-a.yaml > /dev/null
kubectl apply -f manifests/app-b.yaml > /dev/null
kubectl apply -f manifests/app-c.yaml > /dev/null

# echo "🔍 Installaling tools ..."
# bash tools/install-tracee.sh > /dev/null

echo 
echo "************************************"
echo
cat README.txt
echo
