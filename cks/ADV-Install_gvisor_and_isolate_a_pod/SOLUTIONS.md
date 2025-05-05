# Solution

## Install gvizor (apt method)

Doc: https://gvisor.dev/docs/user_guide/containerd/quick_start/

Install those packages (normally already installed)

```
$ sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl gnupg
```

```
$ curl -fsSL https://gvisor.dev/archive.key | sudo gpg --dearmor -o /usr/share/keyrings/gvisor-archive-keyring.gpg

$ echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/gvisor-archive-keyring.gpg] https://storage.googleapis.com/gvisor/releases release main" | sudo tee /etc/apt/sources.list.d/gvisor.list > /dev/null

$ sudo apt-get update && sudo apt-get install -y runsc
```

The procedure is in Gvisor doc for containerd https://gvisor.dev/docs/user_guide/containerd/quick_start/ 

We can see that `containerd-shim-runsc-v1` is installed :

```
$ which containerd-shim-runsc-v1
/usr/bin/containerd-shim-runsc-v1
```

In the same directory as `containerd` :

```
$ which containerd
/usr/bin/containerd
```

The documention show how to configure `containerd` to run `runsc` (**DO NOT DO IT**!)

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

But if we do that, it replaces the actual `/etc/containerd/config.toml`
Furthermode, we cannot just append this block `/etc/containerd/config.toml` because `version = 2` is already declared and also the 2 following plugins : 
- `[plugins."io.containerd.runtime.v1.linux"]`
- `[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]`

So, we only add at the end of `/etc/containerd/config.toml` the last part :

```json
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc]
  runtime_type = "io.containerd.runsc.v1"
```

You can do like this (`-a` for *append*):

cat <<EOF | sudo tee -a /etc/containerd/config.toml > /dev/null
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc]
  runtime_type = "io.containerd.runsc.v1"
EOF


The Kubernets Quistart shows how to install a *CNI*, but we have already one, so we forget this part.

We restart *containerd* :

```
$ sudo systemctl restart containerd
```

We do this installation **on ALL nodes** (controlplane01, node01, etc).


## Create the runtime class

Search for **runtime class** on Kubernetes documentation : https://kubernetes.io/docs/concepts/containers/runtime-class/ pour trouver des exemples :


```yaml
# runtimeclass-runsc.yaml 
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: gvisor
handler: runsc
```

```
$ k apply -f runtimeclass-runsc.yaml 
```

We can see :

```
$ kubectl get runtimeclass
NAME     HANDLER   AGE
gvisor   runsc     7m
```

## Test

We create a test pod in the `team-red` namespace:

```
$ k run pod-gvisor --image ubuntu -n team-red --dry-run=client -o yaml --command -- sleep 3600 > pod-gvisor.yaml
```

We edit the generated yaml to add `runtimeClassName` :

```yaml
# pod-gvisor.yaml 
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod-gvisor
  name: pod-gvisor
  namespace: team-red
spec:
  runtimeClassName: gvisor # ADD
  containers:
  - command:
    - sleep
    - "3600"
    image: ubuntu
    name: pod-gvisor
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

We check :

```
k apply -f pod-gvisor.yaml 
pod/pod-gvisor created

$ k -n team-red get pods -o wide
NAME         READY   STATUS    RESTARTS   AGE   IP           NODE         NOMINATED NODE   READINESS GATES
pod-gvisor   1/1     Running   0          13s   10.0.1.128   k8s-node01   <none>           <none>


$ k -n team-red describe pod/pod-gvisor 
Name:                pod-gvisor
Namespace:           team-red
Priority:            0
Runtime Class Name:  gvisor
...
```



```
$ k -n team-red exec -it pod/pod-gvisor -- bash
root@pod-gvisor:/# apt-get update && apt-get -y install libcap2-bin
...
root@pod-gvisor:/# capsh --print
Current: cap_chown,cap_dac_override,cap_fowner,cap_fsetid,cap_kill,cap_setgid,cap_setuid,cap_setpcap,cap_net_bind_service,cap_sys_chroot,cap_mknod,cap_audit_write,cap_setfcap=ep
Bounding set =cap_chown,cap_dac_override,cap_fowner,cap_fsetid,cap_kill,cap_setgid,cap_setuid,cap_setpcap,cap_net_bind_service,cap_sys_chroot,cap_mknod,cap_audit_write,cap_setfcap
Ambient set = <unsupported>
Current IAB: !cap_dac_read_search,!cap_linux_immutable,!cap_net_broadcast,!cap_net_admin,!cap_net_raw,!cap_ipc_lock,!cap_ipc_owner,!cap_sys_module,!cap_sys_rawio,!cap_sys_ptrace,!cap_sys_pacct,!cap_sys_admin,!cap_sys_boot,!cap_sys_nice,!cap_sys_resource,!cap_sys_time,!cap_sys_tty_config,!cap_lease,!cap_audit_control,!cap_mac_override,!cap_mac_admin,!cap_syslog,!cap_wake_alarm,!cap_block_suspend,!cap_audit_read,!cap_perfmon,!cap_bpf,!cap_checkpoint_restore
Securebits: 037777777777/0xffffffff/32'b11111111111111111111111111111111 (no-new-privs=1)
 secure-noroot: yes (locked)
 secure-no-suid-fixup: yes (locked)
 secure-keep-caps: yes (locked)
uid=0(root) euid=0(root)
gid=0(root)
groups=0(root)
Guessed mode: PURE1E_INIT (2)
```

We see the dropped capabilities (IAB - Inheritable, Ambient, Bounding flags)

```
Current IAB: !cap_dac_read_search,!cap_linux_immutable,!cap_net_broadcast,!cap_net_admin,!cap_net_raw, ...
```

Notable omissions:
- `cap_sys_admin`: very powerful, blocked ➜ ✅
- `cap_net_raw`, `cap_net_admin`: raw networking blocked ➜ ✅
- `cap_sys_ptrace`: cannot trace other processes ➜ ✅

This reflects gVisor's strong isolation model.


# ✅ Going further – Enforcing gVisor for High Security Workloads with OPA Gatekeeper

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
