#!/bin/bash
set -e

SSH_OPTIONS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"

echo "🔧 Installing lab..."
kubectl apply -f manifests/namespaces.yaml > /dev/null

sudo cp /etc/containerd/config.toml /etc/containerd/config.toml.SAVE

# On nodes
for node in $(kubectl get nodes --no-headers | grep -v "control-plane" | awk '{print $1}'); do
  ssh $SSH_OPTIONS vagrant@$node bash <<'EOF'
    set -e
    sudo cp /etc/containerd/config.toml /etc/containerd/config.toml.SAVE
EOF
done

echo 
echo "************************************"
echo
cat README.txt
echo