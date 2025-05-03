# ✅ Solution – Gatekeeper Mutation

## 🔧 OPA Gatekeeper installation

Install OPA Gatekeeper using Helm (from the installation documentation):

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

## 🏷️ Label Mutation

For the first mutation (labels), we use the `AssignMetadata` kind based on the official example (but for `labels` instead of `annotations` and we add the namespace in `match` ):

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
mutation-label-admin-blue   21s
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

## 🔍 How OPA Gatekeeper Integrates with the Kubernetes API Server

Open Policy Agent (OPA) Gatekeeper is a **policy controller** for Kubernetes that enforces fine-grained rules using **Rego policies**. It integrates directly with the Kubernetes control plane by leveraging built-in **admission webhooks**.

### 🕉 Kubernetes Admission Webhooks

Kubernetes includes two types of admission controller webhooks (*admission plugins*), in this order :

- **1. MutatingAdmissionWebhook** – runs before validation, used to **modify** the request (e.g., inject labels, add defaults).
- **2. ValidatingAdmissionWebhook** – runs after built-in admission controllers, used to **accept or reject** a request.

These webhooks are **enabled by default** in most Kubernetes distributions.

### 🔗 How Gatekeeper Hooks into the API Server

OPA Gatekeeper registers itself as both:

- A **ValidatingAdmissionWebhook** – to enforce constraints (deny deployments, pods, etc., that violate policy)
- Optionally, a **MutatingAdmissionWebhook** – to apply mutations via mutation policies (e.g., inject security settings)

Once installed, every resource request (like `kubectl apply`, `create`, `update`) is intercepted by the API Server and passed to Gatekeeper for evaluation.

### ⚙️ How It Works

1. A user applies a resource (e.g., a Pod).
2. The API server sends this request to all registered webhooks.
3. Gatekeeper evaluates the request against all installed **Constraints** and **Templates**.
4. If a rule is violated, Gatekeeper **rejects** the request with a clear error message.
5. If mutation is enabled and applicable, Gatekeeper can **modify** the request before it is persisted.

### 🛠️ Core Concepts

- **ConstraintTemplate**: Defines a policy logic using Rego.
- **Constraint**: Applies that logic to specific Kubernetes resources.
- **Audit**: Gatekeeper can also periodically **scan existing resources** to find violations, not just block new ones.

### 📘 Example Use Cases

- Require all Pods to have specific labels.
- Deny usage of the `:latest` image tag.
- Enforce non-root containers only.
- Disallow hostPath volumes.

