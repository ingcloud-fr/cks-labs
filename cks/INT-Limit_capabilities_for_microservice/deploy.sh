#!/bin/bash
set -e

echo "🔧 Creating lab resources ..."
kubectl apply -f manifests/ > /dev/null

mkdir -p /home/vagrant/manifests
cp manifests/02-webapp.yaml /home/vagrant/manifests/webapp.yaml

echo
echo "************************************"
echo
cat README.txt
echo