#!/bin/bash
set -e

echo "🔧 Creating namespaces..."
kubectl apply -f manifests/namespaces.yaml > /dev/null

echo "🚀 Deploying applications..."
kubectl apply -f manifests/apps.yaml > /dev/null

SSH_OPTIONS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"
CLUSTER=$(kubectl get nodes -oname | awk -F/ '{print $2}' | awk -F- '{print $1}' | uniq)
kubectl label nodes $CLUSTER-node01 node=node01
kubectl label nodes $CLUSTER-controlplane node=controlplane

sudo cp /etc/falco/falco_rules.local.yaml /etc/falco/falco_rules.local.yaml.SAVE

sudo tee /etc/falco/falco_rules.local.yaml > /dev/null <<'EOF'
- rule: Detect Package Management Execution
  desc: Detect execution of package management binaries (e.g. apt, dpkg)
  condition: spawned_process and proc.name in (package_mgmt_binaries)
  output: >
    Package manager execution detected (container=%container.id)
  priority: WARNING
  tags: [process, package_mgmt, suspicious]
EOF
sudo systemctl restart falco
scp $SSH_OPTIONS /etc/falco/falco_rules.local.yaml root@$CLUSTER-node01:/etc/falco/
ssh $SSH_OPTIONS root@$CLUSTER-node01 systemctl restart falco


echo
echo "************************************"
echo
cat README.txt
echo