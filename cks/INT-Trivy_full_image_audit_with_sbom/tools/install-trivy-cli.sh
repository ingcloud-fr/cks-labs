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
sudo apt-get install -y wget apt-transport-https gnupg lsb-release >/dev/null
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor -o /usr/share/keyrings/trivy.gpg
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/trivy.list >/dev/null
sudo apt-get update -y >/dev/null
sudo apt-get install -y trivy >/dev/null


echo "✅ Trivy installed: $(trivy -v)"

