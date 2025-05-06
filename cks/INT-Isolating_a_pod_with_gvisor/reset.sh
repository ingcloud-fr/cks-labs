#!/bin/bash
set -e

echo "🧹 Cleaning up the lab environment..."

kubectl delete ns team-red --ignore-not-found > /dev/null 2>&1
kubectl delete runtimeclass gvisor --ignore-not-found > /dev/null 2>&1

SSH_OPTIONS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"

echo "🗑️  Removing Gvisor locally"

sudo apt-get remove --purge -y runsc > /dev/null
[ -f /etc/apt/sources.list.d/gvisor.list ] && sudo rm -f /etc/apt/sources.list.d/gvisor.list
[ -f /usr/share/keyrings/gvisor-archive-keyring.gpg ] && sudo rm -f /usr/share/keyrings/gvisor-archive-keyring.gpg
sudo apt-get autoremove -y  > /dev/null
sudo apt-get update > /dev/null
[ -f /etc/containerd/config.toml.SAVE ] && sudo mv /etc/containerd/config.toml.SAVE /etc/containerd/config.toml
sudo systemctl restart containerd

# Installation on node
for node in $(kubectl get nodes --no-headers | grep -v "control-plane" | awk '{print $1}'); do
  echo "🗑️  Removing Gvisor remotely on $node..."
  ssh $SSH_OPTIONS vagrant@$node bash <<'EOF'
    set -e
    sudo apt-get remove --purge -y runsc > /dev/null
    [ -f /etc/apt/sources.list.d/gvisor.list ] && sudo rm -f /etc/apt/sources.list.d/gvisor.list
    [ -f /usr/share/keyrings/gvisor-archive-keyring.gpg ] && sudo rm -f /usr/share/keyrings/gvisor-archive-keyring.gpg
    sudo apt-get autoremove -y  > /dev/null
    sudo apt-get update > /dev/null
    [ -f /etc/containerd/config.toml.SAVE ] && sudo mv /etc/containerd/config.toml.SAVE /etc/containerd/config.toml
    sudo systemctl restart containerd
EOF
done

echo "✅ Cleanup complete."