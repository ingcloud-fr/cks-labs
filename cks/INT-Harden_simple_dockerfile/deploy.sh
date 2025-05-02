#!/bin/bash
set -e

echo "🔧 Creating lab resources ..."
cp -r tools/docker ~/docker

echo
echo "************************************"
echo
cat README.txt
echo