#!/bin/bash
set -e

echo "🚀 Deploying manifest..."
kubectl apply -f manifests/ > /dev/null

SSH_OPTIONS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"
CONTROLPLANE=$(kubectl get nodes -oname | grep controlplane | awk -F/ '{print $2}')
NODE=$(kubectl get nodes --no-headers -o wide | grep -v control-plane | awk '{print $1}')
kubectl label nodes $NODE node=node01
kubectl label nodes $CONTROLPLANE node=controlplane

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
scp $SSH_OPTIONS /etc/falco/falco_rules.local.yaml root@$NODE:/etc/falco/
ssh $SSH_OPTIONS root@$NODE systemctl restart falco


echo
echo "************************************"
echo
cat README.txt
echo