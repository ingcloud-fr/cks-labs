#!/bin/bash
set -ex

echo "🧹 Cleaning up the lab..."

SSH_OPTIONS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"

echo "💾 Restoring kubelet-config on controlplane..."
[ -f /tmp/kubelet-config-backup.yaml ] && kubectl -n kube-system replace -f /tmp/kubelet-config-backup.yaml --force > /dev/null 2>&1
[ -f /tmp/kubelet-config-backup.yaml ] && sudo kubeadm upgrade node phase kubelet-config  > /dev/null 2>&1
[ -f /tmp/kubelet-config-backup.yaml ] && sudo systemctl restart kubelet 
[ -f /tmp/kubelet-config-backup.yaml ] && sudo rm /tmp/kubelet-config-backup.yaml

for node in $(kubectl get nodes --no-headers | grep -v "control-plane" | awk '{print $1}'); do
  echo "💾 Restoring kubelet-config on $node..."
  ssh $SSH_OPTIONS vagrant@$node bash <<'EOF'
    [ -f /tmp/kubelet-config-backup.yaml ] && kubectl -n kube-system replace -f /tmp/kubelet-config-backup.yaml --force > /dev/null 2>&1
    [ -f /tmp/kubelet-config-backup.yaml ] && sudo kubeadm upgrade node phase kubelet-config  > /dev/null 2>&1
    [ -f /tmp/kubelet-config-backup.yaml ] && sudo systemctl restart kubelet 
    [ -f /tmp/kubelet-config-backup.yaml ] && sudo rm /tmp/kubelet-config-backup.yaml
EOF
done

echo "✅ Reset complete."