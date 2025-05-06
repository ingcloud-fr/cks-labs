## Solution: Update Kubelet Configuration with Kubeadm

### 🎯 Goal

Ensure `containerLogMaxSize` is set to `10Mi` and `containerLogMaxFiles` to `5` for **all current and future nodes** using the Kubeadm workflow.

---

### ✅ Recommended Kubeadm-based Method

This method ensures:

* **Consistency across all current and future nodes**
* **Integration with kubeadm upgrade and join mechanisms**

### 🧰 Step-by-step Solution

#### 1. Update the Kubelet ConfigMap used by Kubeadm

In the doc search for **kubeadm reconfigure** and look **Applying kubelet configuration changes** : https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-reconfigure/#applying-kubelet-configuration-changes

Edit the default kubelet config stored in a ConfigMap:

```bash
$ k -n kube-system edit cm kubelet-config
```

Inside the `data.kubelet` section, add the following lines:

```yaml
containerLogMaxSize: 5Mi
maxPod: 50
seccompDefault: true
```

This ensures that **future nodes joining the cluster** or **after an upgrade** will receive the correct Kubelet configuration.

#### 2. Update the Kubelet config on the control plane node

On the `controlplane01`:


Run the kubelet config upgrade:

```
sudo kubeadm upgrade node phase kubelet-config
```

This will pull the latest kubelet config from the cluster and write it to:

```
/var/lib/kubelet/config.yaml
```

Verify:

```bash
$ grep -E "maxPods|containerLogMaxSize|seccompDefault" /var/lib/kubelet/config.yaml 
containerLogMaxSize: 5Mi
maxPods: 50
seccompDefault: true
...
```

Restart kubelet:

```
$ sudo systemctl restart kubelet
```

#### 3. Repeat the procedure on node01

SSH into `node01`:

```bash
ssh k8s-node01
```

No need to modify the ConfigMap `kubelet-config` because it's a *configMap* on the cluster and we dit it on the controlplane. 

Apply the same kubelet upgrade:

```bash
$ sudo kubeadm upgrade node phase kubelet-config
$ sudo systemctl restart kubelet
```

Check values:

```bash
$ grep -E "maxPods|containerLogMaxSize|seccompDefault" /var/lib/kubelet/config.yaml 
containerLogMaxSize: 5Mi
maxPods: 50
seccompDefault: true
```

#### 4. (Optional) Verify via Kubelet API

To verify that Kubelet is running with the new config, use:

```bash
$ k get --raw "/api/v1/nodes/<NODE_NAME>/proxy/configz" | jq
```

For instance (and you can see the entire config file with default values) :

```json
$ k get --raw "/api/v1/nodes/k8s-controlplane01/proxy/configz" | jq 
{
  ...
    "maxPods": 50,
 ...
    "containerLogMaxSize": "5Mi",
...
    "seccompDefault": true,
}
```

#### 5. Test

When activated in the Kubelet configuration :

```
seccompDefault: true
```

We force the *RuntimeDefault* profile for any Pod that doesn't explicitly define a seccomp profile, even if it's not visible in the Pod spec. This behavior improves baseline security without requiring changes to each Pod manifest.

👉 In other words:

- The seccompDefault option is enforced by the Kubelet, not injected into the PodSpec: We won't see RuntimeDefault appear in the Pod's YAML output.
- But the runtime applies it silently at container level.
- You can only check via the kubelet API or by looking at the runtime directly (e.g.: crictl inspect or runc).

Wwe create a simple nginx pod :

```
$ k run nginx --image nginx
```

And we check on the node that runs the nginx:

```
$ sudo crictl ps | grep nginx
2577cff32469a       a830707172e80    3 minutes ago    Running     nginx         0        6567edb171f3f       nginx             default

$ sudo crictl inspect 2577cff32469a | jq '.info.runtimeSpec.linux.seccomp'
{
  "architectures": [
    "SCMP_ARCH_X86_64",
    "SCMP_ARCH_X86",
    "SCMP_ARCH_X32"
  ],
  "defaultAction": "SCMP_ACT_ERRNO",
  "syscalls": [
    {
      "action": "SCMP_ACT_ALLOW",
      "names": [
        "accept",
        "accept4",
    ...
```

We see :

```
"defaultAction": "SCMP_ACT_ERRNO"
```

This is the default behavior of the RuntimeDefault seccomp profile: it blocks all syscalls not explicitly allowed.

For information, without *RuntimeDefault* (`RuntimeDefault: false`), we would have :

```
$ sudo crictl inspect ffa1c1d4b10ed | jq '.info.runtimeSpec.linux.seccomp'
null
```

### RESET THE LAB !

⚠️ Important: Don’t forget to run `reset.sh` (or reverse your work) after completing the lab. Leaving the Kubelet configuration with `seccompDefault: true` may cause unexpected behavior in other labs or workloads if they rely on different security profiles.

### ✅ Best Practices & Tips

* Always modify the `kubelet-config` ConfigMap in kubeadm clusters.
* Use `kubeadm upgrade node phase kubelet-config` to safely regenerate configs.
* Restart `kubelet` after changes to apply them immediately.

### 📚 References

* Reconfifure a cluster with kubeadm : https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-reconfigure/#applying-kubelet-configuration-changes
* Kubelet Configuration : https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/ 