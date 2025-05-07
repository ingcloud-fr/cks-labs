#!/bin/bash
set -e

echo "🔧 Creating lab..."
kubectl apply -f manifests/ #> /dev/null 2>&1

echo "🔐 Creating Kubernetes Secret..."
if ! kubectl -n team-blue get secret database-password >/dev/null 2>&1; then
  kubectl -n team-blue create secret generic database-password --from-literal=pass=U3VwZXJTZWNyZXQxMjM= > /dev/null
fi

BACKUP_DIR="/tmp/lab-etcd-backup/"

echo "💾 Backing up etcd certificates and API server config..."
sudo mkdir -p /tmp/lab-etcd-backup

sudo cp /etc/kubernetes/pki/apiserver-etcd-client.* $BACKUP_DIR
sudo cp -r /etc/kubernetes/pki/etcd $BACKUP_DIR
sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml $BACKUP_DIR
sudo cp /etc/kubernetes/manifests/etcd.yaml $BACKUP_DIR

echo "💾 Backing up etcd data and configuration..."
sudo tar czf $BACKUP_DIR/etcd-backup.tgz /var/lib/etcd/ > /dev/null 2>&1


echo
echo "************************************"
echo
cat README.txt
echo
