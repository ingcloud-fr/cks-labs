#!/bin/bash
set -e

echo "🔍 Testing remote Docker daemon with TLS ..."

docker --tlsverify \
  --tlscacert=/opt/docker-certs/ca.pem \
  --tlscert=/opt/docker-certs/cert.pem \
  --tlskey=/opt/docker-certs/key.pem \
  -H=tcp://localhost:2376 info
