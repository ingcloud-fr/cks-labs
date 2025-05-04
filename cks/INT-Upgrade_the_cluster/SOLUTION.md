# ✅ SOLUTION.md – Kubernetes Cluster Upgrade to v1.33

## 🌟 Goal
Upgrade the Kubernetes control plane and node(s) from version **v1.32** to **v1.33** **without downtime** for critical workloads.

## 🧱 Pre-requisites
- Cluster running Kubernetes **v1.32**
- `kubectl` access and admin privileges
- The namespace `team-green` with a **running nginx deployment (2 replicas)**

```
$ k get nodes
NAME                 STATUS   ROLES           AGE     VERSION
k8s-controlplane01   Ready    control-plane   4h39m   v1.32.4
k8s-controlplane02   Ready    control-plane   4h34m   v1.32.4
k8s-node01           Ready    <none>          4h31m   v1.32.4
```

## 🛠️ Step-by-step Solution

Search for *kubeadm upgrade* in official kubernetes documentation : https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/

## Upgrading control plane nodes


### On controlplane01

Changing the package repository and determine which version to upgrade to :


```
$ sudo vi /etc/apt/sources.list.d/kubernetes.list 
$ cat /etc/apt/sources.list.d/kubernetes.list
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /
```

```
$ sudo apt update
...
```

```
$ sudo apt-cache madison kubeadm
   kubeadm | 1.33.0-1.1 | https://pkgs.k8s.io/core:/stable:/v1.33/deb  Packages
```

Upgrade kubeadm:

```
$ sudo apt-mark unhold kubeadm && \
  sudo apt-get update && sudo apt-get install -y kubeadm='1.33.0-*' && \
  sudo apt-mark hold kubeadm
```

We check :

```
$ kubeadm version
kubeadm version: &version.Info{Major:"1", Minor:"33", EmulationMajor:"", EmulationMinor:"", MinCompatibilityMajor:"", MinCompatibilityMinor:"", GitVersion:"v1.33.0", GitCommit:"60a317eadfcb839692a68eab88b2096f4d708f4f", GitTreeState:"clean", BuildDate:"2025-04-23T13:05:48Z", GoVersion:"go1.24.2", Compiler:"gc", Platform:"linux/amd64"}
```

Verify the upgrade plan:

```
$ sudo kubeadm upgrade plan
[preflight] Running pre-flight checks.
[upgrade/config] Reading configuration from the "kubeadm-config" ConfigMap in namespace "kube-system"...
[upgrade/config] Use 'kubeadm init phase upload-config --config your-config-file' to re-upload it.
[upgrade] Running cluster health checks
[upgrade] Fetching available versions to upgrade to
[upgrade/versions] Cluster version: 1.32.4
[upgrade/versions] kubeadm version: v1.33.0
[upgrade/versions] Target version: v1.33.0
[upgrade/versions] Latest version in the v1.32 series: v1.32.4

Components that must be upgraded manually after you have upgraded the control plane with 'kubeadm upgrade apply':
COMPONENT   NODE                 CURRENT   TARGET
kubelet     k8s-controlplane01   v1.32.4   v1.33.0
kubelet     k8s-controlplane02   v1.32.4   v1.33.0
kubelet     k8s-node01           v1.32.4   v1.33.0

Upgrade to the latest stable version:

COMPONENT                 NODE                 CURRENT    TARGET
kube-apiserver            k8s-controlplane01   v1.32.4    v1.33.0
kube-apiserver            k8s-controlplane02   v1.32.4    v1.33.0
kube-controller-manager   k8s-controlplane01   v1.32.4    v1.33.0
kube-controller-manager   k8s-controlplane02   v1.32.4    v1.33.0
kube-scheduler            k8s-controlplane01   v1.32.4    v1.33.0
kube-scheduler            k8s-controlplane02   v1.32.4    v1.33.0
kube-proxy                                     1.32.4     v1.33.0
CoreDNS                                        v1.11.3    v1.12.0
etcd                      k8s-controlplane01   3.5.16-0   3.5.21-0
etcd                      k8s-controlplane02   3.5.16-0   3.5.21-0

You can now apply the upgrade by executing the following command:

	kubeadm upgrade apply v1.33.0
_____________________________________________________________________

The table below shows the current state of component configs as understood by this version of kubeadm.
Configs that have a "yes" mark in the "MANUAL UPGRADE REQUIRED" column require manual config upgrade or
resetting to kubeadm defaults before a successful upgrade can be performed. The version to manually
upgrade to is denoted in the "PREFERRED VERSION" column.

API GROUP                 CURRENT VERSION   PREFERRED VERSION   MANUAL UPGRADE REQUIRED
kubeproxy.config.k8s.io   v1alpha1          v1alpha1            no
kubelet.config.k8s.io     v1beta1           v1beta1             no
_____________________________________________________________________
```

No need to choose a version to upgrade to, there is only on version available : `v1.33.0`

Run the appropriate command :

```
$ sudo kubeadm upgrade apply v1.33.0
[upgrade] Reading configuration from the "kubeadm-config" ConfigMap in namespace "kube-system"...
[upgrade] Use 'kubeadm init phase upload-config --config your-config-file' to re-upload it.
[upgrade/preflight] Running preflight checks
[upgrade] Running cluster health checks
[upgrade/preflight] You have chosen to upgrade the cluster version to "v1.33.0"
[upgrade/versions] Cluster version: v1.32.4
[upgrade/versions] kubeadm version: v1.33.0
[upgrade] Are you sure you want to proceed? [y/N]: y
...
[upgrade/addon] Skipping upgrade of addons because control plane instances [k8s-controlplane02] have not been upgraded
[upgrade/addon] Skipping upgrade of addons because control plane instances [k8s-controlplane02] have not been upgraded

[upgrade] SUCCESS! A control plane node of your cluster was upgraded to "v1.33.0".
[upgrade] Now please proceed with upgrading the rest of the nodes by following the right order.
```

Drain the node :

```
$ kubectl drain k8s-controlplane01 --ignore-daemonsets
node/k8s-controlplane01 cordoned
Warning: ignoring DaemonSet-managed Pods: cilium-spire/spire-agent-xdj95, kube-system/cilium-envoy-kbsgv, kube-system/cilium-v642q, kube-system/kube-proxy-srldt
evicting pod cilium-spire/spire-server-0
evicting pod kube-system/hubble-relay-589fbddbf-7vwtl
evicting pod kube-system/coredns-668d6bf9bc-4fdlm
evicting pod kube-system/cilium-operator-59fcf8695b-j5g4z
evicting pod kube-system/coredns-668d6bf9bc-dxk9b
pod/spire-server-0 evicted
pod/cilium-operator-59fcf8695b-j5g4z evicted
pod/hubble-relay-589fbddbf-7vwtl evicted
pod/coredns-668d6bf9bc-4fdlm evicted
pod/coredns-668d6bf9bc-dxk9b evicted
node/k8s-controlplane01 drained
```

Now we have :

```
$ k get nodes
NAME                 STATUS                     ROLES           AGE     VERSION
k8s-controlplane01   Ready,SchedulingDisabled   control-plane   5h28m   v1.32.4
k8s-controlplane02   Ready                      control-plane   5h23m   v1.32.4
k8s-node01           Ready                      <none>          5h20m   v1.32.4
```

Upgrade kubelet and kubectl : 

```
$ sudo apt-mark unhold kubelet kubectl && \
  sudo apt-get update && sudo apt-get install -y kubelet='1.33.0-*' kubectl='1.33.0-*' && \
  sudo apt-mark hold kubelet kubectl    
```

Restart the kubelet:

```
$ sudo systemctl daemon-reload
$ sudo systemctl restart kubelet
```

```
$ k get nodes
NAME                 STATUS                     ROLES           AGE     VERSION
k8s-controlplane01   Ready,SchedulingDisabled   control-plane   5h28m   v1.33.0
k8s-controlplane02   Ready                      control-plane   5h23m   v1.32.4
k8s-node01           Ready                      <none>          5h20m   v1.32.4
```

Uncordon the node :

```
$ k uncordon k8s-controlplane01
node/k8s-controlplane01 uncordoned
```

ow we have :

```
$ k get nodes
NAME                 STATUS   ROLES           AGE     VERSION
k8s-controlplane01   Ready    control-plane   5h31m   v1.33.0
k8s-controlplane02   Ready    control-plane   5h26m   v1.32.4
k8s-node01           Ready    <none>          5h24m   v1.32.4
```

### On k8-controlplane02 (if it exists)

Same procedure as **k8s-controlplane01** just change `sudo kubeadm upgrade apply v1.33.0` to `sudo kubeadm upgrade node v1.33.0`

Changing the package repository and determine which version to upgrade to :

```
$ sudo vi /etc/apt/sources.list.d/kubernetes.list 
$ cat /etc/apt/sources.list.d/kubernetes.list
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /
```

```
$ sudo apt update
...
```

Upgrade kubeadm:

```
$ sudo apt-mark unhold kubeadm && \
  sudo apt-get update && sudo apt-get install -y kubeadm='1.33.0-*' && \
  sudo apt-mark hold kubeadm
```

We check :

```
$ kubeadm version
kubeadm version: &version.Info{Major:"1", Minor:"33", EmulationMajor:"", EmulationMinor:"", MinCompatibilityMajor:"", MinCompatibilityMinor:"", GitVersion:"v1.33.0", GitCommit:"60a317eadfcb839692a68eab88b2096f4d708f4f", GitTreeState:"clean", BuildDate:"2025-04-23T13:05:48Z", GoVersion:"go1.24.2", Compiler:"gc", Platform:"linux/amd64"}
```

Verify the upgrade plan:

```
$ sudo kubeadm upgrade plan[preflight] Running pre-flight checks.
[upgrade/config] Reading configuration from the "kubeadm-config" ConfigMap in namespace "kube-system"...
[upgrade/config] Use 'kubeadm init phase upload-config --config your-config-file' to re-upload it.
[upgrade] Running cluster health checks
[upgrade] Fetching available versions to upgrade to
W0504 05:30:37.717978   14095 compute.go:93] Different API server versions in the cluster were discovered: v1.33.0 on nodes [k8s-controlplane01], v1.32.4 on nodes [k8s-controlplane02]. Please upgrade your control plane nodes to the same version of Kubernetes
[upgrade/versions] Cluster version: 1.33.0
[upgrade/versions] kubeadm version: v1.33.0
[upgrade/versions] Target version: v1.33.0
[upgrade/versions] Latest version in the v1.33 series: v1.33.0
```

That changes here from the `k8s-controlplane01` part : 

```
$ sudo kubeadm upgrade node
...
...
[upgrade/kubelet-config] The kubelet configuration for this node was successfully upgraded!
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy
```

Drain the node :

```
$ kubectl drain k8s-controlplane02 --ignore-daemonsets
node/k8s-controlplane02 cordoned
Warning: ignoring DaemonSet-managed Pods: cilium-spire/spire-agent-kjlwj, kube-system/cilium-envoy-2z2ch, kube-system/cilium-s2smf, kube-system/kube-proxy-k2fk9
evicting pod kube-system/coredns-674b8bbfcf-ppmq8
pod/coredns-674b8bbfcf-ppmq8 evicted
node/k8s-controlplane02 drained
```

Now we have :

```
$ k get nodes
NAME                 STATUS                     ROLES           AGE     VERSION
k8s-controlplane01   Ready                      control-plane   5h47m   v1.33.0
k8s-controlplane02   Ready,SchedulingDisabled   control-plane   5h42m   v1.32.4
k8s-node01           Ready                      <none>          5h39m   v1.32.4
```

Upgrade kubelet and kubectl : 

```
$ sudo apt-mark unhold kubelet kubectl && \
  sudo apt-get update && sudo apt-get install -y kubelet='1.33.0-*' kubectl='1.33.0-*' && \
  sudo apt-mark hold kubelet kubectl
```

Restart the kubelet:

```
$ sudo systemctl daemon-reload
$ sudo systemctl restart kubelet
```

Now we have :

```
$ k get nodes
NAME                 STATUS                     ROLES           AGE     VERSION
k8s-controlplane01   Ready                      control-plane   5h48m   v1.33.0
k8s-controlplane02   Ready,SchedulingDisabled   control-plane   5h43m   v1.33.0
k8s-node01           Ready                      <none>          5h40m   v1.32.4
```

Uncordon the node :

```
$ k uncordon k8s-controlplane02
node/k8s-controlplane02 uncordoned
```

Now we have :

```
$ k get nodes
NAME                 STATUS   ROLES           AGE     VERSION
k8s-controlplane01   Ready    control-plane   5h49m   v1.33.0
k8s-controlplane02   Ready    control-plane   5h44m   v1.33.0
k8s-node01           Ready    <none>          5h41m   v1.32.4
```

### On worker nodes : k8s-node01


- Documentation : https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/upgrading-linux-nodes/

Changing the package repository and determine which version to upgrade to :


```
$ sudo vi /etc/apt/sources.list.d/kubernetes.list 
$ cat /etc/apt/sources.list.d/kubernetes.list
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /
```

```
$ sudo apt update
...
```

Upgrade kubeadm:

```
$ sudo apt-mark unhold kubeadm && \
  sudo apt-get update && sudo apt-get install -y kubeadm='1.33.0-*' && \
  sudo apt-mark hold kubeadm
```

We check :

```
$ kubeadm version
kubeadm version: &version.Info{Major:"1", Minor:"33", EmulationMajor:"", EmulationMinor:"", MinCompatibilityMajor:"", MinCompatibilityMinor:"", GitVersion:"v1.33.0", GitCommit:"60a317eadfcb839692a68eab88b2096f4d708f4f", GitTreeState:"clean", BuildDate:"2025-04-23T13:05:48Z", GoVersion:"go1.24.2", Compiler:"gc", Platform:"linux/amd64"}
```

Call "kubeadm upgrade" (for worker nodes this upgrades the local kubelet configuration) :

```
$ sudo kubeadm upgrade node
[upgrade] Reading configuration from the "kubeadm-config" ConfigMap in namespace "kube-system"...
[upgrade] Use 'kubeadm init phase upload-config --config your-config-file' to re-upload it.
[upgrade/preflight] Running pre-flight checks
[upgrade/preflight] Skipping prepull. Not a control plane node.
[upgrade/control-plane] Skipping phase. Not a control plane node.
[upgrade/kubeconfig] Skipping phase. Not a control plane node.
W0504 05:46:09.933945   15818 postupgrade.go:117] Using temporary directory /etc/kubernetes/tmp/kubeadm-kubelet-config931950010 for kubelet config. To override it set the environment variable KUBEADM_UPGRADE_DRYRUN_DIR
[upgrade] Backing up kubelet config file to /etc/kubernetes/tmp/kubeadm-kubelet-config931950010/config.yaml
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[upgrade/kubelet-config] The kubelet configuration for this node was successfully upgraded!
[upgrade/addon] Skipping the addon/coredns phase. Not a control plane node.
[upgrade/addon] Skipping the addon/kube-proxy phase. Not a control plane node.
```

Drain the node 

Prepare the node for maintenance by marking it unschedulable and evicting the workloads:

```
$ k drain k8s-node01 --ignore-daemonsets 
node/k8s-node01 cordoned
Warning: ignoring DaemonSet-managed Pods: cilium-spire/spire-agent-76vt5, kube-system/cilium-7l47x, kube-system/cilium-envoy-f45xr, kube-system/kube-proxy-wjn95
evicting pod kube-system/hubble-relay-589fbddbf-bd5pk
evicting pod cilium-spire/spire-server-0
evicting pod kube-system/cilium-operator-59fcf8695b-kdxfk
evicting pod kube-system/coredns-674b8bbfcf-l6557
pod/cilium-operator-59fcf8695b-kdxfk evicted
pod/spire-server-0 evicted
pod/hubble-relay-589fbddbf-bd5pk evicted
pod/coredns-674b8bbfcf-l6557 evicted
node/k8s-node01 drained
```

Upgrade kubelet and kubectl : 

```
$ sudo apt-mark unhold kubelet kubectl && \
  sudo apt-get update && sudo apt-get install -y kubelet='1.33.0-*' kubectl='1.33.0-*' && \
  sudo apt-mark hold kubelet kubectl
```

We restart the kubelet :

```
$ sudo systemctl daemon-reload
$ sudo systemctl restart kubelet
```

Now we have :

```
$ k get nodes
NAME                 STATUS                     ROLES           AGE     VERSION
k8s-controlplane01   Ready                      control-plane   5h59m   v1.33.0
k8s-controlplane02   Ready                      control-plane   5h54m   v1.33.0
k8s-node01           Ready,SchedulingDisabled   <none>          5h51m   v1.33.0
```

Uncordon the node :

```
$ $ k uncordon k8s-node01
node/k8s-node01 uncordoned
```

Now we have :

```
$ k get nodes
NAME                 STATUS   ROLES           AGE     VERSION
k8s-controlplane01   Ready    control-plane   5h49m   v1.33.0
k8s-controlplane02   Ready    control-plane   5h44m   v1.33.0
k8s-node01           Ready    <none>          5h41m   v1.33.0
```

Let's have a look on the app :

```
$ k get all -n team-green 
NAME                         READY   STATUS    RESTARTS   AGE
pod/nginx-5654587fb9-2gkjc   1/1     Running   0          16m
pod/nginx-5654587fb9-nj5vg   1/1     Running   0          16m

NAME              TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/web-svc   ClusterIP   10.99.203.116   <none>        80/TCP    16m

NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx   2/2     2            2           16m

NAME                               DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-5654587fb9   2         2         2       16m
```

