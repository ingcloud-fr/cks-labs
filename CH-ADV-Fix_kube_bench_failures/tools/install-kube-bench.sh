#!/bin/bash
set -e

echo "📦 Downloading latest kube-bench release..."

VERSION=$(curl -s https://api.github.com/repos/aquasecurity/kube-bench/releases/latest | grep '"tag_name":' | cut -d '"' -f4)

echo "🔖 Latest version: $VERSION"

TMP_DIR=$(mktemp -d)
cd $TMP_DIR

curl -sSLO https://github.com/aquasecurity/kube-bench/releases/download/${VERSION}/kube-bench_${VERSION#v}_linux_amd64.tar.gz
tar -xzf kube-bench_${VERSION#v}_linux_amd64.tar.gz

echo "📂 Installing kube-bench to /usr/local/bin..."
sudo mv kube-bench /usr/local/bin/
echo "📂 Installing kube-bench cfg to /etc/kube-bench/cfg ..."
sudo mkdir /etc/kube-bench/
sudo mv cfg /etc/kube-bench/

cd -
rm -rf "$TMP_DIR"

echo "✅ kube-bench installed successfully in /usr/local/bin and config in /etc/kube-bench/cfg !"
# kube-bench version
