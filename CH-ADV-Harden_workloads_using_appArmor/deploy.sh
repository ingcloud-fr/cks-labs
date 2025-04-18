#!/bin/bash
set -e

echo "🔧 Creating lab resources ..."
kubectl apply -f manifests/ > /dev/null

mkdir /home/vagrant/apparmor
cp tools/sec-profile /home/vagrant/apparmor

echo
echo "************************************"
echo
cat README.txt
echo