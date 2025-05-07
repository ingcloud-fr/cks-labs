#!/bin/bash
set -ex

# echo "📦 Fetching latest Trivy version..."
# VERSION=$(curl -s https://api.github.com/repos/aquasecurity/trivy/releases/latest | grep '"tag_name":' | cut -d '"' -f4)
# URL="https://github.com/aquasecurity/trivy/releases/download/${VERSION}/trivy_${VERSION#v}_Linux-64bit.tar.gz"
# echo "⬇️  Downloading Trivy ${VERSION}..."
# cd /tmp
# curl -sL "$URL" -o trivy.tar.gz
# tar -xzf trivy.tar.gz
# sudo mv trivy /usr/local/bin/
# sudo chmod +x /usr/local/bin/trivy


SSH_OPTIONS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"

echo "📦 Installing Trivy CLI on controlplane..."
[ -f /usr/share/keyrings/trivy.gpg ] && sudo rm /usr/share/keyrings/trivy.gpg
[ -f /etc/apt/sources.list.d/trivy.list ] && sudo rm /etc/apt/sources.list.d/trivy.list 
sudo apt-get install -y wget apt-transport-https gnupg lsb-release >/dev/null
wget -4 -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor -o /usr/share/keyrings/trivy.gpg
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/trivy.list >/dev/null
sudo apt-get update -y >/dev/null
sudo apt-get install -y trivy >/dev/null

for node in $(kubectl get nodes --no-headers | grep -v "control-plane" | awk '{print $1}'); do
  echo "📦 Installing Trivy CLI remotely on $node..."
  ssh $SSH_OPTIONS vagrant@$node bash <<'EOF'
    [ -f /usr/share/keyrings/trivy.gpg ] && sudo rm /usr/share/keyrings/trivy.gpg
    [ -f /etc/apt/sources.list.d/trivy.list ] && sudo rm /etc/apt/sources.list.d/trivy.list 
    sudo apt-get install -y wget apt-transport-https gnupg lsb-release >/dev/null
    wget -4 -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor -o /usr/share/keyrings/trivy.gpg
    echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/trivy.list >/dev/null
    sudo apt-get update -y >/dev/null
    sudo apt-get install -y trivy >/dev/null
EOF
done

echo "✅ Trivy installed: $(trivy -v)"

