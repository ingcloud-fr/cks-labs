#!/bin/bash
set -e

echo "🧹 Cleaning up the lab..."

# Restore original daemon.json if backup exists
sudo rm -f /etc/docker/daemon.json
sudo mv /lib/systemd/system/docker.service.bak /lib/systemd/system/docker.service

# Remove certs
sudo rm -rf /etc/docker/certs
sudo rm -rf /opt/docker-certs

# Reload and restart docker
sudo systemctl daemon-reexec
sudo systemctl restart docker.socket
sudo systemctl restart docker

echo "✅ Reset complete."
