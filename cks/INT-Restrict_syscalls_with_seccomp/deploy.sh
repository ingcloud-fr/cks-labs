#!/bin/bash
set -e

echo "🔧 Creating lab resources ..."

# Create namespace if needed
kubectl create ns team-blue > /dev/null

# Ensure profile directory exists
mkdir -p /home/vagrant/profiles

# Copy seccomp profile into home
cp tools/*.json /home/vagrant/profiles/

echo
echo "************************************"
echo
cat README.txt
echo
