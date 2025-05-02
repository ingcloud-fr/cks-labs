#!/bin/bash
set -e

# echo "📦 Fetching latest Trivy version..."
# VERSION=$(curl -s https://api.github.com/repos/aquasecurity/trivy/releases/latest | grep '"tag_name":' | cut -d '"' -f4)
# URL="https://github.com/aquasecurity/trivy/releases/download/${VERSION}/trivy_${VERSION#v}_Linux-64bit.tar.gz"
# echo "⬇️  Downloading Trivy ${VERSION}..."
# cd /tmp
# curl -sL "$URL" -o trivy.tar.gz
# tar -xzf trivy.tar.gz
# sudo mv trivy /usr/local/bin/
# sudo chmod +x /usr/local/bin/trivy

echo "📦 Installing Trivy CLI..."
[ -f /usr/share/keyrings/trivy.gpg ] && sudo rm -f /usr/share/keyrings/trivy.gpg
sudo apt-get install -y wget apt-transport-https gnupg lsb-release >/dev/null
wget -4 -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/trivy.list >/dev/null
sudo apt-get update -qq
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y trivy >/dev/null 2>&1

echo "✅ Trivy installed: $(trivy -v)"