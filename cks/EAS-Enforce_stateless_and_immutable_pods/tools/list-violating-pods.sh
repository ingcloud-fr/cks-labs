#!/bin/bash

echo "🔍 Searching for non-stateless or non-immutable Pods in namespace 'production'..."

kubectl get pods -n production -o json | jq -r '
  .items[] |
  select(
    (.spec.volumes[]?.emptyDir? or .spec.volumes[]?.hostPath?) or
    (.spec.containers[]?.securityContext?.privileged == true) or
    (.spec.containers[]?.securityContext?.allowPrivilegeEscalation == true) or
    (.spec.containers[]?.securityContext?.runAsUser == 0)
  ) |
  .metadata.name
'
