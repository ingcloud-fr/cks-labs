#!/bin/bash
set -e

echo "🔧 Creating lab resources ..."
echo "🔍 Installing tools ..."

if ! command -v trivy &> /dev/null; then
  bash tools/install-trivy-cli.sh > /dev/null
fi

echo "📦 Installing demo-app ..."
cp -r tools/demo-app ~

echo
echo "************************************"
echo
cat README.txt
echo
