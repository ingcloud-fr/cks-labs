#!/bin/bash
set -e

echo "🧹 Cleaning up the lab environment..."

kubectl delete ns team-red --ignore-not-found --force > /dev/null 2>&1
kubectl delete ns team-yellow --ignore-not-found --force > /dev/null 2>&1

echo "🧹 Removing gVisor (runsc) runtime..."

# 1. Supprimer le paquet
sudo apt-get remove --purge -y runsc > /dev/null

# 2. Supprimer les fichiers de dépôt
sudo rm -f /etc/apt/sources.list.d/gvisor.list
sudo rm -f /usr/share/keyrings/gvisor-archive-keyring.gpg

# 3. Nettoyer les paquets inutiles
sudo apt-get autoremove -y  > /dev/null
sudo apt-get update > /dev/null

# 4. /etc/containerd/config.toml

sudo cp /etc/containerd/config.toml /etc/containerd/config.toml.RUNSC
sudo cp /etc/containerd/config.toml.SAVE /etc/containerd/config.toml

# 5. Redémarrer containerd
sudo systemctl restart containerd



echo "✅ Cleanup complete."