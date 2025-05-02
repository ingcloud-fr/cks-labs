#!/bin/bash
set -e

echo "🧹 Cleaning up the lab..."

kubectl delete -f manifests/ --ignore-not-found=true

echo "✅ Reset complete."
