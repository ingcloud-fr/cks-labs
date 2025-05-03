# ✅ Solution – Enforcing Required Labels with Gatekeeper

We base our implementation on the official Gatekeeper how-to guide:
https://open-policy-agent.github.io/gatekeeper/website/docs/howto

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

## 📐 ConstraintTemplate

The first constraint template in the HOW-TO **remains the same**. 

According to the documentation:

> *"Here is an example constraint template that requires all labels described by the constraint to be present"*

```yaml
# k8requiredlabelstemplate.yaml 
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8srequiredlabels # lower case of the kind K8sRequiredLabels
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredLabels
      validation:
        # Schema for the `parameters` field
        openAPIV3Schema:
          type: object
          properties:
            labels:
              type: array
              items:
                type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredlabels

        violation[{"msg": msg, "details": {"missing_labels": missing}}] {
          provided := {label | input.review.object.metadata.labels[label]}
          required := {label | label := input.parameters.labels[_]}
          missing := required - provided
          count(missing) > 0
          msg := sprintf("you must provide labels: %v", [missing])
        }
```

## ✏️ Constraint (Adapted for Pods)

The example targets `Namespaces`, while here we are targeting `Pods`. We also need to apply the constraint only in `team-blue` namespace, and the name of the needed label is `env` :

We modify the constraint example to :

```yaml
# k8requiredlabels.yaml 
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: 
     pods-must-have-label-env # Change the name
spec:
  match:
    namespaces: ["team-blue"] # Add (see the doc just below - match section)
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"] # Change (see api-resource for the kind)
  parameters:
    labels: ["env"]  # Change
```

💡 To identify the kind of a resource:
```bash
$ kubectl api-resources
NAME       SHORTNAMES   APIVERSION       NAMESPACED   KIND
...
pods       po            v1              true         Pod
```
✅ The kind is `Pod`, not `pods` nor `Pods`

## 🚀 Apply the Files

```bash
$ kubectl apply -f k8requiredlabels.yaml
k8srequiredlabels.constraints.gatekeeper.sh/pods-must-have-label-env configured

$ kubectl apply -f k8requiredlabelstemplate.yaml
constrainttemplate.templates.gatekeeper.sh/k8srequiredlabels configured
```

Verify:
```bash
$ kubectl get constrainttemplates.templates.gatekeeper.sh
NAME                AGE
k8srequiredlabels   4m

$ k get k8srequiredlabels.constraints.gatekeeper.sh 
NAME                       ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
pods-must-have-label-env   deny                 0
```

The details :

```yaml
$ k get k8srequiredlabels.constraints.gatekeeper.sh pods-must-have-label-env -o yaml 
...
  spec:
    enforcementAction: deny
    match:
      kinds:
      - apiGroups:
        - ""
        kinds:
        - Pod
      namespaces:
      - team-blue
    parameters:
      labels:
      - env
...
```

## ✅ Test the Validation

Try creating a pod **without** the required label:
```bash
$ kubectl -n team-blue run nginx --image nginx
Error from server (Forbidden): admission webhook "validation.gatekeeper.sh" denied the request: [pods-must-have-label-env] you must provide labels: {"env"}
```
✅ The request was denied as expected.

Try again **with** the label:
```bash
$ kubectl -n team-blue run nginx --image nginx --labels env=prod
pod/nginx created
```
✅ This time the pod is accepted.

Check that other namespaces are **not affected**:
```bash
$ kubectl -n team-green run nginx --image nginx
pod/nginx created
```
✅ Everything is working as intended.

Let's do a bit of theory !

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
