#!/bin/bash
set -e

echo "🧹 Removing built image and containers..."

docker rm -f $(docker ps -aq --filter ancestor=secure-app) 2>/dev/null || true
docker rmi -f secure-app 2>/dev/null || true

echo "✅ Reset complete."
