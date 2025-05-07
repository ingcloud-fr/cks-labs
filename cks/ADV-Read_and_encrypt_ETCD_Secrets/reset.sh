#!/bin/bash
set -e

BACKUP_DIR="/tmp/lab-etcd-backup"

echo "🧹 Cleaning up the lab..."

# Supprimer les ressources Kubernetes
# kubectl -n team-blue delete secret database-password --ignore-not-found=true > /dev/null 2>&1
kubectl delete -f manifests/ --ignore-not-found=true > /dev/null 2>&1

echo "♻️ Restoring etcd data, certificates and kube-apiserver configuration..."
if [ -d "$BACKUP_DIR" ]; then
  # Restaurer les certificats etcd et apiserver
  # sudo cp $BACKUP_DIR/apiserver-etcd-client.* /etc/kubernetes/pki/
  # sudo cp -r $BACKUP_DIR/etcd /etc/kubernetes/pki/

  # Restaurer les manifestes kube-apiserver et etcd
  sudo cp $BACKUP_DIR/kube-apiserver.yaml /etc/kubernetes/manifests/
  sudo cp $BACKUP_DIR/etcd.yaml /etc/kubernetes/manifests/

  # Restaurer les données etcd
  if [ -f "$BACKUP_DIR/etcd-backup.tgz" ]; then
    sudo rm -rf /var/lib/etcd/*
    sudo tar xzf $BACKUP_DIR/etcd-backup.tgz -C /
  fi

  echo "🗑️ Removing backup directory..."
  sudo rm -rf "$BACKUP_DIR"
else
  echo "⚠️ No etcd backup found. Skipping restore."
fi

echo "✅ Reset complete."
