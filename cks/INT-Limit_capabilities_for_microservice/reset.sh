#!/bin/bash
set -e

echo "🧹 Cleaning up the lab..."

# Delete resources using manifest files
kubectl delete ns team-blue --ignore-not-found=true # > /dev/null 2>&1
rm -rf /home/vagrant/manifests/

echo "✅ Reset complete."