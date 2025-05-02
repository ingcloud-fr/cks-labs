#!/bin/bash
set -e

echo "🧹 Cleaning up lab resources..."

# Supprime la source APT Trivy
echo "🧽 Removing Trivy APT source and key..."
sudo rm -f /etc/apt/sources.list.d/trivy.list
sudo rm -f /usr/share/keyrings/trivy.gpg

# Supprime Trivy
if command -v trivy >/dev/null 2>&1; then
  echo "🗑️  Uninstalling Trivy..."
  sudo apt-get remove -y trivy >/dev/null
fi

# Optionnel : supprime le cache apt
sudo apt-get autoremove -y >/dev/null
sudo apt-get clean

echo "📦 Removing demo-app ..."
sudo rm -rf ~/demo-app

echo "✅ Lab cleanup complete."