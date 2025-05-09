#!/bin/bash
set -e

echo "🎯 Creating lab resources ..."
echo "🔧 Backing up manifests, kubelet config, and etcd data permissions..."

MANIFEST_DIR="/etc/kubernetes/manifests"
BACKUP_MANIFEST_DIR="/etc/kubernetes/backup"
ETCD_DIR="/var/lib/etcd"
KUBELET_CONFIGMAP_BACKUP="/etc/kubernetes/backup/kubelet-config-cm.yaml"
SSH_OPTIONS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"

sudo mkdir -p $BACKUP_MANIFEST_DIR

# Backup control plane manifests
for file in etcd.yaml kube-apiserver.yaml kube-controller-manager.yaml kube-scheduler.yaml; do
    if [ ! -f "$BACKUP_MANIFEST_DIR/$file" ]; then
        sudo cp "$MANIFEST_DIR/$file" "$BACKUP_MANIFEST_DIR/$file"
    fi
done

# Backup etcd data directory permissions
ETCD_PERM_FILE="$BACKUP_MANIFEST_DIR/etcd-dir-perm.txt"
if [ ! -f "$ETCD_PERM_FILE" ]; then
    stat -c "%a" $ETCD_DIR | sudo tee $ETCD_PERM_FILE > /dev/null
fi

KUBELET_CONFIGMAP_BACKUP="/etc/kubernetes/backup/kubelet-config-cm.yaml"
if [ ! -f "$KUBELET_CONFIGMAP_BACKUP" ]; then
  sudo mkdir -p /etc/kubernetes/backup/
  kubectl get configmap kubelet-config -n kube-system -o yaml | sudo tee "$KUBELET_CONFIGMAP_BACKUP" > /dev/null
fi


# echo "🔐 Making the cluster insecure..."

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
echo -n "⏳ Waiting for kube-apiserver to come back"
until kubectl get nodes &> /dev/null; do
  echo -n "."
  sleep 1
done
echo


# === Disable Client Cert Auth in etcd (2.2 must FAIL) ===
sudo sed -i 's/client-cert-auth=true/client-cert-auth=false/' /etc/kubernetes/manifests/etcd.yaml

# === Enable profiling on kube-controller-manager (1.3.2 must FAIL) - ALREADY set on true ===
# sudo sed -i '/--profiling/d' $MANIFEST_DIR/kube-controller-manager.yaml

# === Enable profiling on kube-scheduler (1.4.1 must FAIL) - ALREADY set on true ===
# sudo sed -i '/--profiling/d' $MANIFEST_DIR/kube-scheduler.yaml

# Installation kube-bench

if [ ! -d /etc/kube-bench/ ]; then
  echo "📦 Downloading latest kube-bench release..."
  VERSION=$(curl -s https://api.github.com/repos/aquasecurity/kube-bench/releases/latest | grep '"tag_name":' | cut -d '"' -f4)
  echo "🔖 Kube-bench latest version: $VERSION"
  TMP_DIR=$(mktemp -d)
  cd $TMP_DIR
  curl -sSLO https://github.com/aquasecurity/kube-bench/releases/download/${VERSION}/kube-bench_${VERSION#v}_linux_amd64.tar.gz
  tar -xzf kube-bench_${VERSION#v}_linux_amd64.tar.gz
  echo "📦 Installing kube-bench to /usr/local/bin..."
  sudo mv kube-bench /usr/local/bin/
  echo "📦 Installing kube-bench cfg to /etc/kube-bench/cfg ..."
  # [ -d /etc/kube-bench/ ] && sudo rm -rf /etc/kube-bench/
  sudo mkdir -p /etc/kube-bench/
  sudo mv cfg /etc/kube-bench/
  cd - > /dev/null
  rm -rf "$TMP_DIR"
  echo "✅ kube-bench installed successfully"
else
  echo "✅ kube-bench already installed on controlplane"
fi

# === ON 1RST NODE ###

node=$(kubectl get nodes --no-headers | grep -v "control-plane" | awk '{print $1}')
echo "📦 Installing kube-bench on $node..."
ssh $SSH_OPTIONS vagrant@$node bash <<'EOF'
  set -e
  
  KUBELET_CONFIGMAP_BACKUP="/etc/kubernetes/backup/kubelet-config-cm.yaml"
  if [ ! -f "$KUBELET_CONFIGMAP_BACKUP" ]; then
    echo "🔧 Backing up kubelet config..."
    sudo mkdir -p /etc/kubernetes/backup/
    kubectl get configmap kubelet-config -n kube-system -o yaml | sudo tee "$KUBELET_CONFIGMAP_BACKUP" > /dev/null
  fi

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
  sudo kubeadm upgrade node phase kubelet-config > /dev/null 2>&1
  sudo systemctl restart kubelet > /dev/null
  if [ ! -d /etc/kube-bench/ ]; then
    VERSION=$(curl -s https://api.github.com/repos/aquasecurity/kube-bench/releases/latest | grep '"tag_name":' | cut -d '"' -f4)
    TMP_DIR=$(mktemp -d)
    cd $TMP_DIR
    curl -sSLO https://github.com/aquasecurity/kube-bench/releases/download/${VERSION}/kube-bench_${VERSION#v}_linux_amd64.tar.gz
    tar -xzf kube-bench_${VERSION#v}_linux_amd64.tar.gz
    echo "📂 Installing kube-bench to /usr/local/bin..."
    sudo mv kube-bench /usr/local/bin/
    echo "📂 Installing kube-bench cfg to /etc/kube-bench/cfg ..."
    #[ -d /etc/kube-bench/ ] && sudo rm -rf /etc/kube-bench/
    sudo mkdir -p /etc/kube-bench/
    sudo mv cfg /etc/kube-bench/
    cd - > /dev/null
    rm -rf "$TMP_DIR"
  else 
    echo "✅ kube-bench already installed on $(hostname)"
  fi
EOF

echo
echo "************************************"
echo
cat README.txt
echo
echo "✅ Lab setup completed."

