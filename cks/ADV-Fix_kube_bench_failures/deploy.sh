#!/bin/bash
set -e

echo "🎯 Creating lab resources ..."
echo "🔧 Backing up manifests, kubelet config, and etcd data permissions..."

MANIFEST_DIR="/etc/kubernetes/manifests"
BACKUP_MANIFEST_DIR="/etc/kubernetes/backup"
ETCD_DIR="/var/lib/etcd"
KUBELET_CONFIGMAP_BACKUP="/etc/kubernetes/backup/kubelet-config-cm.yaml"

sudo mkdir -p $BACKUP_MANIFEST_DIR

# Backup control plane manifests
for file in etcd.yaml kube-apiserver.yaml kube-controller-manager.yaml kube-scheduler.yaml; do
    if [ ! -f "$BACKUP_MANIFEST_DIR/$file" ]; then
        sudo cp "$MANIFEST_DIR/$file" "$BACKUP_MANIFEST_DIR/$file"
    fi
done

# echo "💾 Backing up kubelet ConfigMap..."
if [ ! -f "$KUBELET_CONFIGMAP_BACKUP" ]; then
  kubectl get configmap kubelet-config -n kube-system -o yaml | sudo tee "$KUBELET_CONFIGMAP_BACKUP" > /dev/null
fi

# Backup etcd data directory permissions
ETCD_PERM_FILE="$BACKUP_MANIFEST_DIR/etcd-dir-perm.txt"
if [ ! -f "$ETCD_PERM_FILE" ]; then
    stat -c "%a" $ETCD_DIR | sudo tee $ETCD_PERM_FILE > /dev/null
fi

echo "🔐 Making the cluster insecure..."

# === Modify Permissions ===
# echo "🔐 Modifying etcd data directory permissions..."
sudo chmod 755 $ETCD_DIR

# === Modify kube-apiserver.yaml to BREAK some tests ===
# echo "🔐 Making kube-apiserver insecure..."
sudo sed -i '/--authorization-mode=/d' $MANIFEST_DIR/kube-apiserver.yaml
sudo sed -i '/- --secure-port=6443/a \    - --authorization-mode=AlwaysAllow' $MANIFEST_DIR/kube-apiserver.yaml

# === Enable profiling on kube-apiserver (1.2.15 must FAIL) - ALREADY set on true ===
# sudo sed -i '/--profiling/d' $MANIFEST_DIR/kube-apiserver.yaml

# Attente que l'API server redémarre proprement
sleep 2
echo "⏳ Waiting for kube-apiserver to come back..."
until kubectl get nodes &> /dev/null; do
  sleep 1
done

# === Disable Client Cert Auth in etcd (2.2 must FAIL) ===
sudo sed -i 's/client-cert-auth=true/client-cert-auth=false/' /etc/kubernetes/manifests/etcd.yaml

# === Enable profiling on kube-controller-manager (1.3.2 must FAIL) - ALREADY set on true ===
# sudo sed -i '/--profiling/d' $MANIFEST_DIR/kube-controller-manager.yaml

# === Enable profiling on kube-scheduler (1.4.1 must FAIL) - ALREADY set on true ===
# sudo sed -i '/--profiling/d' $MANIFEST_DIR/kube-scheduler.yaml

# === Modify kubelet config map to break 4.2.1 and 4.2.2 ===
# echo "🔧 Patching kubelet config via ConfigMap..."
KUBELET_CM=$(kubectl get configmap kubelet-config -n kube-system -o json)
MODIFIED_CM=$(echo "$KUBELET_CM" | jq '
  .data.kubelet = (
    .data.kubelet
    | split("\n")
    | map(
        if test("^[ ]*enabled:[ ]*false$") then "    enabled: true"
        elif test("^[ ]*mode:[ ]*Webhook$") then "  mode: AlwaysAllow"
        else .
        end
      )
    | join("\n")
  )
')
echo "$MODIFIED_CM" | kubectl apply -f - > /dev/null

# === Apply config to node ===
# echo "🔁 Applying modified kubelet config..."
sudo kubeadm upgrade node phase kubelet-config

# === Restart kubelet ===
# echo "🔄 Restarting kubelet..."
sudo systemctl restart kubelet


# Installation kube-bench
tools/install-kube-bench.sh

echo
echo "************************************"
echo
cat README.txt
echo
echo "✅ Lab setup completed."

