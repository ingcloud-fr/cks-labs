#!/bin/bash
set -e

SSH_OPTIONS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"

echo "🧹 Cleaning up the lab..."

# Delete resources using manifest files
#kubectl delete -f manifests/ --ignore-not-found=true > /dev/null 2>&1

echo "📦 Removing Trivy remotely on controlplane..."
sudo apt-get remove --purge -y trivy > /dev/null

[ -f /usr/share/keyrings/trivy.gpg ] && sudo rm /usr/share/keyrings/trivy.gpg
[ -f /etc/apt/sources.list.d/trivy.list ] && sudo rm /etc/apt/sources.list.d/trivy.list 
sudo apt-get autoremove -y  > /dev/null


for node in $(kubectl get nodes --no-headers | grep -v "control-plane" | awk '{print $1}'); do
  echo "📦 Removing Trivy remotely on $node..."
  ssh $SSH_OPTIONS vagrant@$node bash <<'EOF'
    sudo apt-get remove --purge -y trivy > /dev/null
    [ -f /usr/share/keyrings/trivy.gpg ] && sudo rm /usr/share/keyrings/trivy.gpg
    [ -f /etc/apt/sources.list.d/trivy.list ] && sudo rm /etc/apt/sources.list.d/trivy.list 
        sudo apt-get autoremove -y  > /dev/null
EOF
done


echo "✅ Reset complete."