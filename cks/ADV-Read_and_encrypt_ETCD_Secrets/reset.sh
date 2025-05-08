#!/bin/bash
set -e

BACKUP_DIR="/tmp/lab-etcd-backup"
KEEP_BACKUP=true
SSH_OPTIONS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"

echo "🧹 Cleaning up the lab (CAN TAKE SEVERAL MINUTES)..."

# Supprimer les ressources Kubernetes
# kubectl -n team-blue delete secret database-password --ignore-not-found=true > /dev/null 2>&1
# kubectl delete -f manifests/ --ignore-not-found=true > /dev/null # 2>&1

echo "♻️ Restoring etcd data, certificates and kube-apiserver configuration..."
if [ -d "$BACKUP_DIR" ]; then

  # Restaurer les certificats etcd et apiserver
  # sudo cp $BACKUP_DIR/apiserver-etcd-client.* /etc/kubernetes/pki/
  # sudo cp -r $BACKUP_DIR/etcd /etc/kubernetes/pki/

  echo "♻️ Restoring etcd data and manifest"
  # Stop kube-apiserver first
  sudo mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/kube-apiserver.yaml.bak-lab-etcd
  echo -n "⏳ Waiting for kube-apiserver container to stop"
  while sudo crictl ps | grep -q "apiserver"; do
    echo -n "."
    sleep 1
  done
  echo
  echo "✅ Kube-apiserver container is stopped."

  # Then stop etcd
  sudo mv /etc/kubernetes/manifests/etcd.yaml /tmp/etcd.yaml.bak-lab-etcd
  echo -n "⏳ Waiting for etcd container to stop"
  while sudo crictl ps | grep -q "etcd"; do
    echo -n "."
    sleep 1
  done
  echo
  echo "✅ etcd container is stopped."

  echo "🔄 Etcd and Kupe-apiserver are stopped ... restoring the data now !"
  # 2. Supprimer les données
  sudo rm -rf /var/lib/etcd/
  # 3. Restaurer le snapshot dans /var/lib/etcd
  if [ ! -f "$BACKUP_DIR/etcd-snapshot" ]; then
    echo "❌ Missing etcd snapshot: $BACKUP_DIR/etcd-snapshot"
    exit 1
  fi
  sudo ETCDCTL_API=3 etcdctl snapshot restore $BACKUP_DIR/etcd-snapshot --data-dir /var/lib/etcd > /dev/null 2>&1
  echo "Etcd data restored !"
  # Redémarrer etcd
  echo "♻️ Restoring ETCD..."
  sudo cp $BACKUP_DIR/etcd.yaml /etc/kubernetes/manifests/etcd.yaml

  # Attente redemarrage etcd
  echo -n "⏳ Waiting for etcd to be recreated by the kubelet"
  until sudo crictl ps | grep -q "etcd"; do 
    echo -n "."
    sleep 1; 
  done
  echo
  echo "✅ Etcd is restarted"
  # Restaurer le manifeste kube-apiserver
  sudo cp "$BACKUP_DIR/kube-apiserver.yaml" /etc/kubernetes/manifests/
  echo "♻️  Restored kube-apiserver.yaml"
  
  echo -n "⏳ Waiting for kube-apiserver to be Ready"
  until kubectl get --raw=/healthz >/dev/null 2>&1; do
    echo -n "."
    sleep 1
  done
  echo
  echo "✅ kube-apiserver is restarted"

  # Redemarrage des kubelets sur toutes les nodes
  echo "🚀 Restarting kubelet on controlplane..."
  sudo systemctl restart kubelet
  for node in $(kubectl get nodes --no-headers | grep -v "control-plane" | awk '{print $1}'); do
    echo "🚀 Restarting kubelet on $node..."
    ssh $SSH_OPTIONS vagrant@$node bash <<'EOF'
      sudo systemctl restart kubelet
EOF
  done

  if [ "$KEEP_BACKUP" = false ]; then
    sudo rm -rf "$BACKUP_DIR"
  else
    echo "🛡️  Backup folder kept at $BACKUP_DIR. You may delete it manually later."
  fi
else
  echo "⚠️ No etcd backup found. Skipping restore."
fi

echo "✅ Reset complete."
