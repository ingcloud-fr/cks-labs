# ✅ Solution – Gatekeeper Mutation

## 🔧 Installation

Install OPA Gatekeeper using Helm:

```bash
$ helm repo add gatekeeper https://open-policy-agent.github.io/gatekeeper/charts
"gatekeeper" has been added to your repositories

$ helm install gatekeeper/gatekeeper --name-template=gatekeeper --namespace gatekeeper-system --create-namespace
NAME: gatekeeper
LAST DEPLOYED: Tue Apr 15 08:39:25 2025
NAMESPACE: gatekeeper-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

---

## 🏷️ Label Mutation

For the first mutation (labels), we use the `AssignMetadata` kind based on the official example (but for labels instead of annotations and add the namespace):

```yaml
# mutation1.yaml 
apiVersion: mutations.gatekeeper.sh/v1
kind: AssignMetadata
metadata:
  name: mutation-label-admin-blue 
spec:
  match:
    scope: Namespaced
    namespaces: ["team-blue"]
  location: "metadata.labels.admin"
  parameters:
    assign:
      value: "admin-blue"
```

Apply the mutation:

```bash
$ kubectl apply -f mutation1.yaml
assignmetadata.mutations.gatekeeper.sh/mutation-label-admin-blue created
```

Check the mutation object:
```bash
$ kubectl -n team-blue get assignmetadata.mutations.gatekeeper.sh 
NAME                        AGE
mutation-label-admin-blue   2m
```

Test with a basic pod:
```bash
$ kubectl -n team-blue run nginx --image nginx
pod/nginx created

$ kubectl -n team-blue describe pod nginx
Labels:           admin=admin-blue
                  run=nginx
```
✅ The label `admin=admin-blue` was correctly injected.

Optional dry-run to preview:
```bash
$ kubectl -n team-blue run nginx --image nginx --dry-run=server -o yaml
...
metadata:
  labels:
    admin: admin-blue
    run: nginx
  ...
```

---

## 🔐 SeccompProfile Mutation

This mutation injects a default seccomp profile (`RuntimeDefault`) into pods created in the `team-purple` namespace.

We base it on the official example:
https://open-policy-agent.github.io/gatekeeper/website/docs/mutation/#setting-security-context-of-a-specific-container-in-a-pod-in-a-namespace-to-be-non-privileged

But we apply the following modifications:

- It targets the pod's `spec.securityContext`, not a specific container, so we remove `.containers[name:foo]` in `location:`.
- In `securityContext`, we want to inject the field `seccompProfile` with value `type: RuntimeDefault`.
- Instead of assigning a boolean (`assign.value: false`), we assign a nested object (`assign.value.type: RuntimeDefault`).
- The `pathTests` block lets Gatekeeper check if a field exists or not before applying the mutation. It is optional in our case but included as a comment for learning purposes.

```yaml
# mutation2.yaml 
apiVersion: mutations.gatekeeper.sh/v1
kind: Assign
metadata:
  # Name of the mutation policy
  name: add-seccomp-profile-in-pods-team-purple
spec:
  # Target the object types this mutation applies to
  applyTo:
  - groups: [""]          # "" means the core API group (e.g., Pods, Services, etc.)
    kinds: ["Pod"]         # We want to mutate Pods
    versions: ["v1"]       # API version of the Pod

  match:
    scope: Namespaced      # Apply only in Namespaced resources
    namespaces: ["team-purple"]  # Limit this mutation to the team-purple namespace
    kinds:
    - apiGroups: ["*"]     # Match any API group (useful in generic templates)
      kinds: ["Pod"]       # Match Pods only

  # Location in the Pod spec where the value should be assigned
  location: spec.securityContext.seccompProfile

  parameters:
    assign:
      # This is the value to inject
      value:
        type: RuntimeDefault

    # Optional: only mutate if the field exists or not
    # pathTests:
    # - subPath: spec.securityContext.seccompProfile
    #   condition: MustExist   # Only mutate if the field already exists
    #   condition: MustNotExist   # Only mutate if the field does not exist
```

Apply the mutation:
```bash
$ kubectl apply -f mutation2.yaml
assign.mutations.gatekeeper.sh/add-seccomp-profile-in-pods-team-purple created
```

Check the mutation object:
```bash
$ kubectl -n team-purple get assign.mutations.gatekeeper.sh
NAME                                      AGE
add-seccomp-profile-in-pods-team-purple   12s
```

Test the result:
```bash
$ kubectl -n team-purple run nginx --image=nginx --dry-run=server -o yaml
...
spec:
  ...
  securityContext:
    seccompProfile:
      type: RuntimeDefault
  ...
```
✅ The seccomp profile was correctly injected.

---

## 🧪 Control Case: team-green

Check that pods in `team-green` are not mutated:
```bash
$ kubectl -n team-green run nginx --image nginx --dry-run=server -o yaml
...
metadata:
  labels:
    run: nginx
  ...
spec:
  securityContext: {}
  ...
```
✅ No mutation applied.

---

## 🧹 Cleanup

Uninstall Gatekeeper:
```bash
$ helm list -n gatekeeper-system
$ helm uninstall gatekeeper -n gatekeeper-system
release "gatekeeper" uninstalled
```

We can reset the lab :

```
$ ./reset.sh
```
