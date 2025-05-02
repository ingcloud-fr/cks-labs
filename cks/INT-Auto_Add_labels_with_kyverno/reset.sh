#!/bin/bash
set -e

echo "🧹 Cleaning up the lab..."

kubectl delete clusterpolicies add-env-label --ignore-not-found > /dev/null 2>&1
kubectl delete ns autolabel --ignore-not-found=true > /dev/null 2>&1

echo "✅ Reset complete."

echo "You can uninstall kyverno running : $ helm uninstall kyverno -n kyverno"