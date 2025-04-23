#!/bin/bash
set -e

echo "🧹 Cleaning up the lab environment..."
kubectl delete ns team-green --force --ignore-not-found > /dev/null 2>&1
kubectl delete ns team-blue --force --ignore-not-found > /dev/null 2>&1
kubectl delete ns team-red --force --ignore-not-found > /dev/null 2>&1
CLUSTER=$(kubectl get nodes -oname | awk -F/ '{print $2}' | awk -F- '{print $1}' | uniq)
kubectl label nodes $CLUSTER-node01 node- > /dev/null 2>&1
kubectl label nodes $CLUSTER-controlplane node- > /dev/null 2>&1
echo "# Your custom rules!" | sudo tee /etc/falco/falco_rules.local.yaml > /dev/null
sudo systemctl restart falco
SSH_OPTIONS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"
ssh $SSH_OPTIONS root@$CLUSTER-node01 'echo "# Your custom rules!" | sudo tee /etc/falco/falco_rules.local.yaml > /dev/null'
ssh $SSH_OPTIONS root@$CLUSTER-node01 'sudo systemctl restart falco'


echo "✅ Cleanup complete."