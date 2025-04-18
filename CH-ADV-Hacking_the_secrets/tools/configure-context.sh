#!/bin/bash

# Save ~/.kube/config
cp ~/.kube/config ~/.kube/config.SAVE

# Extract the token from the SA token secret
TOKEN=$(kubectl -n team-red get secret restricted-user-secret -o jsonpath="{.data.token}" | base64 -d)

# Get cluster info
CLUSTER_NAME=$(kubectl config view -o jsonpath="{.clusters[0].name}")
SERVER=$(kubectl config view -o jsonpath="{.clusters[0].cluster.server}")
CA_CERT=$(kubectl config view --raw -o jsonpath="{.clusters[0].cluster.certificate-authority-data}")

echo "${CA_CERT}" | base64 -d > /tmp/ca.crt

# Set user credentials using the service account token
kubectl config set-credentials restricted-user --token="${TOKEN}"

# Reconfigure the cluster context if needed
kubectl config set-cluster ${CLUSTER_NAME} \
  --server="${SERVER}" \
  --certificate-authority=/tmp/ca.crt \
  --embed-certs=true

# Set the context
kubectl config set-context restricted@infra-prod \
  --cluster=${CLUSTER_NAME} \
  --user=restricted-user \
  --namespace=team-red

# Reminder
# echo "🔁 You can now switch to the restricted context with:"
# echo "    kubectl config use-context restricted@infra-prod"
# echo "And return to admin with:"
# echo "    kubectl config use-context kubernetes-admin@kubernetes"