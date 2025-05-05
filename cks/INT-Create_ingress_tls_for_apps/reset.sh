#!/bin/bash
set -e

SSH_OPTIONS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"

echo "🧹 Cleaning up the lab..."
sudo sed -i '/127\.0\.0\.1.*www\.my-web-site\.org/d' /etc/hosts

for node in $(kubectl get nodes --no-headers | grep -v "control-plane" | awk '{print $1}'); do
  ssh $SSH_OPTIONS $node sudo sed -i '/127\.0\.0\.1.*www\.my-web-site\.org/d' /etc/hosts
done

kubectl delete -f manifests/ --ignore-not-found=true > /dev/null
kubectl delete secret secret-tls -n team-web --ignore-not-found=true > /dev/null
echo "🔧 Uninstalling nginx controler..."
helm uninstall ingress-nginx -n ingress-nginx --wait --ignore-not-found > /dev/null
kubectl delete namespace ingress-nginx --ignore-not-found=true > /dev/null

echo "✅ Reset complete."
