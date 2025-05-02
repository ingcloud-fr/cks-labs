#!/bin/bash
set -e

echo "🧹 Cleaning up the lab..."

kubectl delete ns team-red --ignore-not-found=true

echo "✅ Reset complete."
