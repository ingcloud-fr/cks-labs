#!/bin/bash
set -e

echo "🧹 Cleaning up the lab environment..."
kubectl delete ns team-green --force --ignore-not-found > /dev/null 2>&1
kubectl delete ns team-orange --force --ignore-not-found > /dev/null 2>&1
kubectl delete ns team-red --force --ignore-not-found > /dev/null 2>&1

rm -rf ~/manifests