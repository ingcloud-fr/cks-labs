#!/bin/bash
set -e

echo "🔧 Creating lab resources ..."

SSH_OPTIONS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"

echo "💾 Backing up kubelet-config on controlplane..."
kubectl -n kube-system get configmap kubelet-config -o yaml > /tmp/kubelet-config-backup.yaml
sudo kubeadm upgrade node phase kubelet-config > /dev/null 2>&1
sudo systemctl restart kubelet > /dev/null 2>&1

for node in $(kubectl get nodes --no-headers | grep -v "control-plane" | awk '{print $1}'); do
  echo "💾 Backing up kubelet-config on $node..."
  ssh $SSH_OPTIONS vagrant@$node bash <<'EOF'
    kubectl -n kube-system get configmap kubelet-config -o yaml > /tmp/kubelet-config-backup.yaml
    sudo kubeadm upgrade node phase kubelet-config > /dev/null  2>&1
    sudo systemctl restart kubelet > /dev/null 2>&1
EOF
done

echo "✅ Lab is ready !"









echo
echo "************************************"
echo
cat README.txt
echo