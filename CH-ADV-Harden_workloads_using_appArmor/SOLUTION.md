# Solution

## 🛡️ Applying AppArmor to Kubernetes Workloads

In this lab, we aim to secure workloads using **AppArmor** profiles. The exercise focuses on two scenarios:

1. Applying AppArmor to a single-container deployment (created by the user).
2. Updating an existing multi-container deployment to apply AppArmor to only **one** container.

---

## 🔧 Step-by-Step Solution

### 1. SSH into the node `k8s-node01`

From the control plane:
```bash
ssh k8s-node01
```

---

### 2. Install AppArmor

📦 AppArmor is not always installed by default. Use the following commands on `k8s-node01`:

```bash
sudo apt update && sudo apt install -y apparmor apparmor-utils
```

Check if AppArmor is enabled:
```bash
sudo aa-status
```

If not enabled at boot, you may need to set the GRUB parameters to include `apparmor=1 security=apparmor`, then reboot the node.

---

### 3. Load the AppArmor Profile

A file named `sec-profile` is provided in `/home/vagrant/apparmor/`. Move it to the right directory and load it:

```bash
sudo mkdir -p /etc/apparmor.d/
sudo cp /home/vagrant/apparmor/sec-profile /etc/apparmor.d/high-secure
sudo apparmor_parser -r /etc/apparmor.d/high-secure
```

Check if it is loaded:
```bash
sudo aa-status | grep high-secure
```

---

### 4. Label the node `k8s-node01`

```bash
kubectl label node k8s-node01 apparmor/enabled=true
```

This label is used to schedule pods only to the node where AppArmor is installed.

---

### 5. Create the Deployment with AppArmor (Single Container)

The deployment must:
- be named `apparmor`
- use `nginx:1.27.1`
- be scheduled on the node using the `apparmor/enabled=true` label
- contain a container named `c1` using the AppArmor profile

📁 Here's how the container spec **must** include the AppArmor profile (modern syntax):

```yaml
spec:
  containers:
    - name: c1
      image: nginx:1.27.1
      securityContext:
        appArmorProfile:
          type: Localhost
          localhostProfile: high-secure
```

Node selector:
```yaml
spec:
  nodeSelector:
    apparmor/enabled: "true"
```

Apply the manifest:
```bash
kubectl apply -f manifests/01-deployment-single-container.yaml
```

---

### 6. Troubleshoot if Pod Does Not Start

The AppArmor profile is **very strict**, it forbids all file writes:
```text
deny /** w,
```
This will break many applications.

Get logs:
```bash
kubectl logs deploy/apparmor
```

If needed, describe the pod:
```bash
kubectl describe pod -l app=apparmor
```

---

### 7. Patch the Multi-Container Deployment

A deployment is already provided in `manifests/02-deployment-two-containers.yaml` with **2 containers**: `nginx` and `sidecar`.

Only one of them should use the AppArmor profile. Let's say we apply it to `sidecar`. Patch the deployment like this:

```yaml
spec:
  containers:
    - name: sidecar
      image: busybox
      command: ["sleep", "3600"]
      securityContext:
        appArmorProfile:
          type: Localhost
          localhostProfile: high-secure
```

Then apply:
```bash
kubectl apply -f manifests/02-deployment-two-containers.yaml
```

✅ Verify that the pod starts successfully and AppArmor is applied only to `sidecar`.

---

### 8. Remove the AppArmor Label from the Node

At the end of the lab, clean up the node label:

```bash
kubectl label node k8s-node01 apparmor/enabled-
```

✅ This removes the `apparmor/enabled` label.

---

## 📚 References

- AppArmor GA in Kubernetes: https://kubernetes.io/docs/tutorials/security/apparmor/
- AppArmor profile syntax: https://gitlab.com/apparmor/apparmor/-/wikis/Documentation

---

✅ You now understand how to enforce AppArmor using the **new GA method** at the container level in Kubernetes!

