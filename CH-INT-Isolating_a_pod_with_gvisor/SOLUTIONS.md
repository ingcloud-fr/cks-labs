# Solution

## Install gvizor (apt method)

Doc: https://gvisor.dev/docs/user_guide/containerd/quick_start/

Normalement installé :

```
$ sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl gnupg
```

```
$ curl -fsSL https://gvisor.dev/archive.key | sudo gpg --dearmor -o /usr/share/keyrings/gvisor-archive-keyring.gpg

$ echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/gvisor-archive-keyring.gpg] https://storage.googleapis.com/gvisor/releases release main" | sudo tee /etc/apt/sources.list.d/gvisor.list > /dev/null

$ sudo apt-get update && sudo apt-get install -y runsc
```

Dans la doc pour containerd https://gvisor.dev/docs/user_guide/containerd/quick_start/ on peut lire la procédure :

Now, we can see that `containerd-shim-runsc-v1` is installed :

```
$ which containerd-shim-runsc-v1
/usr/bin/containerd-shim-runsc-v1
```

In the same directory as `containerd` :

```
$ which containerd
/usr/bin/containerd
```

```
cat <<EOF | sudo tee /etc/containerd/config.toml
version = 2
[plugins."io.containerd.runtime.v1.linux"]
  shim_debug = true
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  runtime_type = "io.containerd.runc.v2"
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc]
  runtime_type = "io.containerd.runsc.v1"
EOF
```

Si on ajoute tout ce bloc, `containerd` plante au redemarrage car dans `/etc/containerd/config.toml`, `version = 2` est déjà déclarée ainsi que les plugins suivants 
- `[plugins."io.containerd.runtime.v1.linux"]`
- `[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]`

On ne va ajouter à la fin de `/etc/containerd/config.toml` que la dernière partie :

```json
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc]
  runtime_type = "io.containerd.runsc.v1"
```

On relance containerd

```
$ sudo systemctl restart containerd
```

On répète cette installation sur **TOUTES les nodes** du cluster (node01, etc)

## Test

On regarde la doc kubernetes en recherchant **runtime class** : https://kubernetes.io/docs/concepts/containers/runtime-class/ pour trouver des exemples :


```yaml
# runtimeclass-runsc.yaml 
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: gvisor
handler: runsc
```

On crée un pod de test pour le namespace `team-red` :

```
$ k run pod-gvizor --image busybox -n team-red --dry-run=client -o yaml --command -- sleep 3600 > pod-gvisor.yaml
```

On l'édite pour ajouter la `runtimeClassName` :

```yaml
# pod-gvisor.yaml 
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod-gvizor
  name: pod-gvizor
  namespace: team-red
spec:
  runtimeClassName: gvisor # ADD
  containers:
  - command:
    - sleep
    - "3600"
    image: busybox
    name: pod-gvizor
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

On vérifie :

```
$ k apply -f pod-gvisor.yaml 
pod/pod-gvizor created

$ k -n team-red get pods -o wide
NAME         READY   STATUS    RESTARTS   AGE   IP           NODE         NOMINATED NODE   READINESS GATES
pod-gvizor   1/1     Running   0          52s   10.0.1.250   k8s-node01   <none>           <none>


$ k -n team-red describe pod/pod-gvizor 
Name:                pod-gvizor
Namespace:           team-red
Priority:            0
Runtime Class Name:  gvisor
...
```

## Pour aller plus loin

- Utiliser un mutating avec OPA Gatekeeper pour ajouter automatiquement `runtimeClassName: gvizor` pour le namespace team-red (ou un validating qui rejeterait le pod/deploy/rs s'il n'a pas `runtimeClassName: gvizor` )

---

# ✅ Solution – Enforcing gVisor for High Security Workloads (Gatekeeper)

## 🎯 Goals

- ❌ Reject all Pods and Deployments **without** the label `security=high` in namespace `team-red`.
- ✅ Automatically **inject `runtimeClassName: gvisor`** if the label is present but the runtime is missing.
- ✅ Apply these rules to both `Pod` and `Deployment` resources.

---

## 1️⃣ Validation Constraint – Require `security=high` in `team-red`

### 📦 Template: `required-label`
```yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8srequiredsecuritylabel
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredSecurityLabel
      validation:
        openAPIV3Schema:
          type: object
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredsecuritylabel

        violation[{
          "msg": msg
        }] {
          input.review.object.metadata.namespace == "team-red"
          not input.review.object.metadata.labels["security"]
          msg := "Missing required label 'security=high' in team-red namespace"
        }
```

### 📦 Constraint: `require-security-high`
```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredSecurityLabel
metadata:
  name: require-security-high
spec:
  match:
    namespaces: ["team-red"]
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
      - apiGroups: ["apps"]
        kinds: ["Deployment"]
```

---

## 2️⃣ Mutation – Inject `runtimeClassName: gvisor` when `security=high`

### 📦 Mutation (Assign): `set-runtime-gvisor-if-security-high`
```yaml
apiVersion: mutations.gatekeeper.sh/v1
kind: Assign
metadata:
  name: set-runtime-gvisor-if-security-high
spec:
  applyTo:
    - groups: ["", "apps"]
      versions: ["v1"]
      kinds: ["Pod", "Deployment"]
  match:
    scope: Namespaced
    namespaces: ["team-red"]
    labelSelector:
      matchLabels:
        security: high
  location: "spec.runtimeClassName"
  parameters:
    assign:
      value: "gvisor"
```

📝 **Note**:
- This applies to both `Pod` and `Deployment.spec.template.spec.runtimeClassName`.
- If you want it to target only Pods created **directly**, you can drop `Deployment` from the `applyTo` block.

---

## ✅ Example Workflow

1. Create a Deployment **without label**:
```bash
kubectl -n team-red apply -f nginx.yaml
# ❌ Rejected: missing required label
```

2. Add label `security=high`:
```yaml
metadata:
  labels:
    security: high
```

3. Re-apply → Gatekeeper injects `runtimeClassName: gvisor`:
```bash
kubectl apply -f nginx.yaml
# ✅ Accepted: label present, runtime injected
```

4. Verify the Pod:
```bash
kubectl -n team-red get pod -o=jsonpath='{.spec.runtimeClassName}'
# Output: gvisor
```

---

## 🧹 Cleanup
```bash
kubectl delete constrainttemplates k8srequiredsecuritylabel
kubectl delete k8srequiredsecuritylabel require-security-high
kubectl delete assign set-runtime-gvisor-if-security-high
```

---

## 🔐 Domain: System Hardening (SH)
**Difficulty: Difficult**
