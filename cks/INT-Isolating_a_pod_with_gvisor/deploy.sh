#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

SSH_OPTIONS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"

echo "🔧 Creating namespaces..."
kubectl apply -f manifests/namespaces.yaml > /dev/null

echo "📦 Installing gVisor locally..."
curl -fsSL https://gvisor.dev/archive.key | sudo gpg --dearmor -o /usr/share/keyrings/gvisor-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/gvisor-archive-keyring.gpg] https://storage.googleapis.com/gvisor/releases release main" | \
  sudo tee /etc/apt/sources.list.d/gvisor.list > /dev/null
sudo apt-get update -qq >/dev/null 2>&1
sudo apt-get install -y runsc >/dev/null 2>&1
sudo cp /etc/containerd/config.toml /etc/containerd/config.toml.SAVE

cat <<EOF | sudo tee -a /etc/containerd/config.toml > /dev/null

[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc]
  runtime_type = "io.containerd.runsc.v1"
EOF

sudo systemctl restart containerd >/dev/null 2>&1

for node in $(kubectl get nodes --no-headers | grep -v "control-plane" | awk '{print $1}'); do
  echo "📦 Installing gVisor remotely on $node..."
  ssh $SSH_OPTIONS vagrant@$node bash <<'EOF'
    set -e
    export DEBIAN_FRONTEND=noninteractive
    curl -fsSL https://gvisor.dev/archive.key | sudo gpg --dearmor -o /usr/share/keyrings/gvisor-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/gvisor-archive-keyring.gpg] https://storage.googleapis.com/gvisor/releases release main" | \
      sudo tee /etc/apt/sources.list.d/gvisor.list > /dev/null
    sudo apt-get update -qq >/dev/null 2>&1
    sudo apt-get install -y runsc >/dev/null 2>&1
    sudo cp /etc/containerd/config.toml /etc/containerd/config.toml.SAVE
    cat <<EOF2 | sudo tee -a /etc/containerd/config.toml > /dev/null

[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc]
runtime_type = "io.containerd.runsc.v1"
EOF2
    sudo systemctl restart containerd >/dev/null 2>&1
EOF
done

echo
echo "************************************"
echo
cat README.txt
echo
