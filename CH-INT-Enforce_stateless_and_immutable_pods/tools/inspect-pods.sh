#!/bin/bash
echo "🔍 Listing pods with volumes and securityContext..."

for pod in $(kubectl get pods -n production -o jsonpath='{.items[*].metadata.name}'); do
  echo "=== $pod ==="
  kubectl get pod "$pod" -n production -o=jsonpath='{.spec.volumes}' | jq .
  kubectl get pod "$pod" -n production -o=jsonpath='{.spec.containers[*].securityContext}' | jq .
  echo
done
