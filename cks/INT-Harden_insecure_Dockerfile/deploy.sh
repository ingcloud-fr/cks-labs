#!/bin/bash
set -e

echo "🔧 Creating lab resources ..."
mkdir -p /home/vagrant/docker
cp tools/* /home/vagrant/docker

echo
echo "************************************"
echo
cat README.txt
echo