#!/bin/bash
set -e

echo "🧹 Restoring original manifests and kubelet config..."

MANIFEST_DIR="/etc/kubernetes/manifests"
BACKUP_MANIFEST_DIR="/etc/kubernetes/backup"
KUBELET_CONFIGMAP_BACKUP="/etc/kubernetes/backup/kubelet-config-cm.yaml"
ETCD_DIR="/var/lib/etcd"
SSH_OPTIONS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"

# Restore manifests
for file in etcd.yaml kube-apiserver.yaml kube-controller-manager.yaml kube-scheduler.yaml; do
  if [ -f "$BACKUP_MANIFEST_DIR/$file" ]; then
    sudo cp "$BACKUP_MANIFEST_DIR/$file" "$MANIFEST_DIR/$file"
  fi
done

echo "🔐 Restoring etcd data directory permissions..."
sudo chmod 700 $ETCD_DIR

# Attente que l'API server redémarre proprement
sleep 2
echo -n "⏳ Waiting for kube-apiserver to come back"
until kubectl get nodes &> /dev/null; do
  echo -n "."
  sleep 1
done
echo

# Restore kubelet configmap from backup
echo "🔐 Restoring Kubelet ConfigMap..."
if [ -f "$KUBELET_CONFIGMAP_BACKUP" ]; then
  echo "🔁 Restoring kubelet configmap..."
  echo "🧨 Deleting existing kubelet-config ConfigMap..."
  kubectl delete configmap kubelet-config -n kube-system > /dev/null
  echo "🔁 Recreating kubelet-config ConfigMap from backup..."
  kubectl create -f $KUBELET_CONFIGMAP_BACKUP > /dev/null 2>&1
  sudo kubeadm upgrade node phase kubelet-config > /dev/null 2>&1
  echo "🔄 Restarting kubelet..."
  sudo systemctl restart kubelet > /dev/null
fi

# Delete kube-bench
# sudo rm -f /usr/local/bin/kube-bench > /dev/null 2>&1
# sudo -rf /etc/kube-bench > /dev/null 2>&1

# === ON 1RST NODE ###

node=$(kubectl get nodes --no-headers | grep -v "control-plane" | awk '{print $1}')
ssh $SSH_OPTIONS vagrant@$node bash <<'EOF'
  set -e
  
  KUBELET_CONFIGMAP_BACKUP="/etc/kubernetes/backup/kubelet-config-cm.yaml"
  echo "🔐 Restoring Kubelet ConfigMap..."
  # Restore kubelet configmap from backup
  if [ -f "$KUBELET_CONFIGMAP_BACKUP" ]; then
    echo "🔁 Restoring kubelet configmap..."
    echo "🧨 Deleting existing kubelet-config ConfigMap..."
    kubectl delete configmap kubelet-config -n kube-system > /dev/null
    echo "🔁 Recreating kubelet-config ConfigMap from backup..."
    kubectl create -f $KUBELET_CONFIGMAP_BACKUP > /dev/null 2>&1
    sudo kubeadm upgrade node phase kubelet-config > /dev/null 2>&1
    echo "🔄 Restarting kubelet..."
    sudo systemctl restart kubelet > /dev/null
  fi

  # Delete kube-bench
  # sudo rm -f /usr/local/bin/kube-bench > /dev/null 2>&1
  # sudo -rf /etc/kube-bench > /dev/null 2>&1
EOF

# Delete backup
# rm -rf $BACKUP_MANIFEST_DIR > /dev/null 2>&1

echo "✅ Reset complete."
