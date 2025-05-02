#!/bin/bash
set -e

echo "🧹 Cleaning up the lab..."

# Delete namespace and its contents
kubectl delete ns team-blue --ignore-not-found=true > /dev/null 2>&1

# Remove local seccomp profile directory
rm -rf /home/vagrant/profiles/

echo "✅ Reset complete."
