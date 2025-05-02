#!/bin/bash
set -e

echo "🧹 Cleaning up the lab environment (please be patient)..."
kubectl delete --force --ignore-not-found -f manifests/ > /dev/null 2>&1
CONTROLPLANE=$(kubectl get nodes -oname | grep controlplane | awk -F/ '{print $2}')
NODE=$(kubectl get nodes --no-headers -o wide | grep -v control-plane | awk '{print $1}')


kubectl label nodes $NODE node- > /dev/null 2>&1
kubectl label nodes $CONTROLPLANE node- > /dev/null 2>&1
echo "# Your custom rules!" | sudo tee /etc/falco/falco_rules.local.yaml > /dev/null
sudo systemctl restart falco
SSH_OPTIONS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"
ssh $SSH_OPTIONS root@$NODE 'echo "# Your custom rules!" | sudo tee /etc/falco/falco_rules.local.yaml > /dev/null'
ssh $SSH_OPTIONS root@$NODE 'sudo systemctl restart falco'


echo "✅ Cleanup complete."