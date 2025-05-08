#!/bin/bash
set -e

BACKUP_DIR="/tmp/lab-etcd-backup/"

echo "🔧 Creating lab..."

echo "💾 Backing up etcd certificates and API server config..."
sudo mkdir -p /tmp/lab-etcd-backup
sudo cp /etc/kubernetes/pki/apiserver-etcd-client.* $BACKUP_DIR
sudo cp -r /etc/kubernetes/pki/etcd $BACKUP_DIR
sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml $BACKUP_DIR
sudo cp /etc/kubernetes/manifests/etcd.yaml $BACKUP_DIR
echo "💾 Backing up etcd data and configuration..."
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/apiserver-etcd-client.crt \
  --key=/etc/kubernetes/pki/apiserver-etcd-client.key \
  snapshot save $BACKUP_DIR/etcd-snapshot > /dev/null 2>&1

kubectl apply -f manifests/ > /dev/null 2>&1

echo "🔐 Creating Kubernetes Secret..."
if ! kubectl -n team-blue get secret database-password >/dev/null 2>&1; then
  kubectl -n team-blue create secret generic database-password --from-literal=password=SuperSecret123 --save-config=true > /dev/null
fi

echo
echo "************************************"
echo
cat README.txt
echo
