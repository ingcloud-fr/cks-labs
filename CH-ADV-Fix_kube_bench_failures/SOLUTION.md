# 🛡️ Solution Guide for kube-bench Lab

## 🧰 kube-bench Setup and Version Handling

We can read at install :

✅ kube-bench installed successfully in /usr/local/bin and config in /etc/kube-bench/cfg 

If we do :

```
$ kube-bench help
...
      --config string                     config file (default is ./cfg/config.yaml)
  -D, --config-dir string                 config directory (default "/etc/kube-bench/cfg")
...
```

➡️ No need to use `--config-dir`, as the `cfg` is already in `/etc/kube-bench`.

We run it with vagrant account :

```
$ kube-bench run

error looking for file /var/lib/etcd/default.etcd: stat /var/lib/etcd/default.etcd: permission denied
```

🔐 We cannot run it as `vagrant`, so we try with `sudo`:

```
$ sudo kube-bench run
Warning: Kubernetes version was not auto-detected because kubectl could not connect to the Kubernetes server. This may be because the kubeconfig information is missing or has credentials that do not match the server. Assuming default version 1.18
Warning: Kubernetes version was not auto-detected because kubectl could not connect to the Kubernetes server. This may be because the kubeconfig information is missing or has credentials that do not match the server. Assuming default version 1.18
[INFO] 1 Master Node Security Configuration
[INFO] 1.1 Master Node Configuration Files
...
```

⚠️  We have two warnings that indicates that *kube-bench* cannot auto-detect the kubernetes version (it uses kubectl and kubectl need a kubeconfig file, but root has no kubeconfig file), we will use the `--version` option :

```
$ kubelet --version
Kubernetes v1.32.3
```

Or anything else to get the kubernetes version (`k get nodes -o wide` for instance)

⚠️  If you don't put the version, it will consider that you're in 1.18 and the report will be different, as the test IDs won't match. The numbering of kube-bench tests depends on the benchmark profile used and the version of Kubernetes targeted.

We can run *kube-bench* for all the tests and look at the asked ones :

```
$ sudo kube-bench run --version 1.32
[INFO] 1 Control Plane Security Configuration
...
```

But it's not easy (and not quick) to read and to retreive the good ones

A better way for this lab, is to use the number of the tests with `--check` or `-c` options, and we will not dispay the remediations :

```
$ sudo kube-bench run --version 1.32 --noremediations -c "1.1.11,1.2.6,1.2.7,1.2.8,1.2.15,1.2.22,1.2.23,1.2.24,1.3.2,1.4.1,2.1,2.2,4.2.1,4.2.2,4.2.11"
Warning: Kubernetes version was not auto-detected because kubectl could not connect to the Kubernetes server. This may be because the kubeconfig information is missing or has credentials that do not match the server. Assuming default version 1.18
[INFO] 1 Control Plane Security Configuration
[INFO] 1.1 Control Plane Node Configuration Files
[FAIL] 1.1.11 Ensure that the etcd data directory permissions are set to 700 or more restrictive (Automated)
[INFO] 1.2 API Server
[FAIL] 1.2.6 Ensure that the --authorization-mode argument is not set to AlwaysAllow (Automated)
[FAIL] 1.2.7 Ensure that the --authorization-mode argument includes Node (Automated)
[FAIL] 1.2.8 Ensure that the --authorization-mode argument includes RBAC (Automated)
[FAIL] 1.2.15 Ensure that the --profiling argument is set to false (Automated)
[PASS] 1.2.22 Ensure that the --service-account-key-file argument is set as appropriate (Automated)
[PASS] 1.2.23 Ensure that the --etcd-certfile and --etcd-keyfile arguments are set as appropriate (Automated)
[PASS] 1.2.24 Ensure that the --tls-cert-file and --tls-private-key-file arguments are set as appropriate (Automated)
[INFO] 1.3 Controller Manager
[FAIL] 1.3.2 Ensure that the --profiling argument is set to false (Automated)
[INFO] 1.4 Scheduler
[FAIL] 1.4.1 Ensure that the --profiling argument is set to false (Automated)

== Summary master ==
3 checks PASS
7 checks FAIL
0 checks WARN
0 checks INFO

[INFO] 2 Etcd Node Configuration
[INFO] 2 Etcd Node Configuration
[PASS] 2.1 Ensure that the --cert-file and --key-file arguments are set as appropriate (Automated)
[FAIL] 2.2 Ensure that the --client-cert-auth argument is set to true (Automated)

== Summary etcd ==
1 checks PASS
1 checks FAIL
0 checks WARN
0 checks INFO

[INFO] 3 Control Plane Configuration

== Summary controlplane ==
0 checks PASS
0 checks FAIL
0 checks WARN
0 checks INFO

[INFO] 4 Worker Node Security Configuration
[INFO] 4.2 Kubelet
[FAIL] 4.2.1 Ensure that the --anonymous-auth argument is set to false (Automated)
[FAIL] 4.2.2 Ensure that the --authorization-mode argument is not set to AlwaysAllow (Automated)
[PASS] 4.2.11 Verify that the RotateKubeletServerCertificate argument is set to true (Manual)

== Summary node ==
1 checks PASS
2 checks FAIL
0 checks WARN
0 checks INFO

[INFO] 5 Kubernetes Policies

== Summary policies ==
0 checks PASS
0 checks FAIL
0 checks WARN
0 checks INFO

== Summary total ==
10 checks PASS
5 checks FAIL
0 checks WARN
0 checks INFO
```

- Note : A warning is still remaining, but the test IDs seems to match with the lab requirements.

ℹ️ We observe 15 checks evaluated: **10 FAIL**, **5 PASS**. We will focuse on FAILED ones.

## 🔧 Fixing 1.1.11 - Etcd Directory Permissions on Controlplane

Now we want to see the remediations so we remove `--noremediations` option :

```
$ sudo kube-bench run --version 1.32 -c "1.1.11"
Warning: Kubernetes version was not auto-detected because kubectl could not connect to the Kubernetes server. This may be because the kubeconfig information is missing or has credentials that do not match the server. Assuming default version 1.18
[INFO] 1 Control Plane Security Configuration
[INFO] 1.1 Control Plane Node Configuration Files
[FAIL] 1.1.11 Ensure that the etcd data directory permissions are set to 700 or more restrictive (Automated)

== Remediations master ==
1.1.11 On the etcd server node, get the etcd data directory, passed as an argument --data-dir,
from the command 'ps -ef | grep etcd'.
Run the below command (based on the etcd data directory found above). For example,
chmod 700 /var/lib/etcd
...
```

We apply 1.1.11 :

```
$ sudo grep data-dir /etc/kubernetes/manifests/etcd.yaml 
    - --data-dir=/var/lib/etcd
```

We test again :

```
$ sudo kube-bench run --version 1.32 -c "1.1.11"
Warning: Kubernetes version was not auto-detected because kubectl could not connect to the Kubernetes server. This may be because the kubeconfig information is missing or has credentials that do not match the server. Assuming default version 1.18
[INFO] 1 Control Plane Security Configuration
[INFO] 1.1 Control Plane Node Configuration Files
[PASS] 1.1.11 Ensure that the etcd data directory permissions are set to 700 or more restrictive (Automated)
```

✅ Test passes.

## 🔧 Fixing API Server Tests: 1.2.6–1.2.8, 1.2.15

```
$ sudo kube-bench run --version 1.32 -c "1.2.6,1.2.7,1.2.8,1.2.15"
Warning: Kubernetes version was not auto-detected because kubectl could not connect to the Kubernetes server. This may be because the kubeconfig information is missing or has credentials that do not match the server. Assuming default version 1.18
[INFO] 1 Control Plane Security Configuration
[INFO] 1.2 API Server
[FAIL] 1.2.6 Ensure that the --authorization-mode argument is not set to AlwaysAllow (Automated)
[FAIL] 1.2.7 Ensure that the --authorization-mode argument includes Node (Automated)
[FAIL] 1.2.8 Ensure that the --authorization-mode argument includes RBAC (Automated)
[FAIL] 1.2.15 Ensure that the --profiling argument is set to false (Automated)

== Remediations master ==
1.2.6 Edit the API server pod specification file /etc/kubernetes/manifests/kube-apiserver.yaml
on the control plane node and set the --authorization-mode parameter to values other than AlwaysAllow.
One such example could be as below.
--authorization-mode=RBAC

1.2.7 Edit the API server pod specification file /etc/kubernetes/manifests/kube-apiserver.yaml
on the control plane node and set the --authorization-mode parameter to a value that includes Node.
--authorization-mode=Node,RBAC

1.2.8 Edit the API server pod specification file /etc/kubernetes/manifests/kube-apiserver.yaml
on the control plane node and set the --authorization-mode parameter to a value that includes RBAC,
for example `--authorization-mode=Node,RBAC`.

1.2.15 Edit the API server pod specification file /etc/kubernetes/manifests/kube-apiserver.yaml
on the control plane node and set the below parameter.
--profiling=false
```

💡 A good habit is to save the `kube-apiserver.yaml` in case of a misconfiguration, copy it somewhere outside the manifest directory, for instance :

```
$ sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml /tmp
```

We edit `/etc/kubernetes/manifests/kube-apiserver.yaml`

```yaml
...
spec:
  containers:
  - command:
    - kube-apiserver
      ...
    - --authorization-mode=RBAC # CHANGE AlwaysAllow to Node,RBAC (tests 1.2.6, 1.2.7, 1.2.8)
    - --profiling=false # ADD (test 1.2.15)
     ...
...
```

Wait for the *kube-apiserver* to restart, then run *kube-bench* again :

```
$ sudo kube-bench run --version 1.32 -c "1.2.6,1.2.7,1.2.8,1.2.15"
Warning: Kubernetes version was not auto-detected because kubectl could not connect to the Kubernetes server. This may be because the kubeconfig information is missing or has credentials that do not match the server. Assuming default version 1.18
[INFO] 1 Control Plane Security Configuration
[INFO] 1.2 API Server
[PASS] 1.2.6 Ensure that the --authorization-mode argument is not set to AlwaysAllow (Automated)
[PASS] 1.2.7 Ensure that the --authorization-mode argument includes Node (Automated)
[PASS] 1.2.8 Ensure that the --authorization-mode argument includes RBAC (Automated)
[PASS] 1.2.15 Ensure that the --profiling argument is set to false (Automated)
```

✅ Test passes.

## 🔧 Fixing Controller Manager: 1.3.2

```
$ $ sudo kube-bench run --version 1.32 -c "1.3.2"
Warning: Kubernetes version was not auto-detected because kubectl could not connect to the Kubernetes server. This may be because the kubeconfig information is missing or has credentials that do not match the server. Assuming default version 1.18
[INFO] 1 Control Plane Security Configuration
[INFO] 1.3 Controller Manager
[FAIL] 1.3.2 Ensure that the --profiling argument is set to false (Automated)

== Remediations master ==
1.3.2 Edit the Controller Manager pod specification file /etc/kubernetes/manifests/kube-controller-manager.yaml
on the control plane node and set the below parameter.
--profiling=false
```

We edit `/etc/kubernetes/manifests/kube-controller-manager.yaml` :

```yaml
spec:
  containers:
  - command:
    - kube-controller-manager
    - --profiling=false  # ADD
    ...
```

We run again the test :

```
$ sudo kube-bench run --version 1.32 -c "1.3.2"
Warning: Kubernetes version was not auto-detected because kubectl could not connect to the Kubernetes server. This may be because the kubeconfig information is missing or has credentials that do not match the server. Assuming default version 1.18
[INFO] 1 Control Plane Security Configuration
[INFO] 1.3 Controller Manager
[PASS] 1.3.2 Ensure that the --profiling argument is set to false (Automated)
```

✅ Test passes.

## 🔧 Fixing Controller Manager: 1.3.2


```
$ sudo kube-bench run --version 1.32 -c "1.4.1"
Warning: Kubernetes version was not auto-detected because kubectl could not connect to the Kubernetes server. This may be because the kubeconfig information is missing or has credentials that do not match the server. Assuming default version 1.18
[INFO] 1 Control Plane Security Configuration
[INFO] 1.4 Scheduler
[FAIL] 1.4.1 Ensure that the --profiling argument is set to false (Automated)

== Remediations master ==
1.4.1 Edit the Scheduler pod specification file /etc/kubernetes/manifests/kube-scheduler.yaml file
on the control plane node and set the below parameter.
--profiling=false
```

We edit `/etc/kubernetes/manifests/kube-scheduler.yaml`

```yaml
spec:
  containers:
  - command:
    - kube-scheduler
    - --profiling=false
   ...
```

We run the test again :

```
$ sudo kube-bench run --version 1.32 -c "1.4.1"
Warning: Kubernetes version was not auto-detected because kubectl could not connect to the Kubernetes server. This may be because the kubeconfig information is missing or has credentials that do not match the server. Assuming default version 1.18
[INFO] 1 Control Plane Security Configuration
[INFO] 1.4 Scheduler
[PASS] 1.4.1 Ensure that the --profiling argument is set to false (Automated)
```

✅ Test passes.

## 🔧 Fixing Etcd: 2.2

```
$ sudo kube-bench run --version 1.32 -c "2.2"
...
[INFO] 2 Etcd Node Configuration
[INFO] 2 Etcd Node Configuration
[FAIL] 2.2 Ensure that the --client-cert-auth argument is set to true (Automated)

== Remediations etcd ==
2.2 Edit the etcd pod specification file /etc/kubernetes/manifests/etcd.yaml on the master
node and set the below parameter.
--client-cert-auth="true"
```

We edit `/etc/kubernetes/manifests/etcd.yaml` :

```yaml
spec:
  containers:
  - command:
    - etcd
    ...
    - --client-cert-auth=true # CHANGE false to true
    ....
```

We wait a few secondes, and we run *kube-bench* again :

```
$ sudo kube-bench run --version 1.32 -c "2.2"
...
[INFO] 2 Etcd Node Configuration
[INFO] 2 Etcd Node Configuration
[PASS] 2.2 Ensure that the --client-cert-auth argument is set to true (Automated)
```

✅ Test passes.

## ⚙️ Fixing Kubelet Tests: 4.2.1 & 4.2.2 (Upgrade-safe)

```
$ sudo kube-bench run --version 1.32 -c "4.2.1,4.2.2"
...
[INFO] 4 Worker Node Security Configuration
[INFO] 4.2 Kubelet
[FAIL] 4.2.1 Ensure that the --anonymous-auth argument is set to false (Automated)
[FAIL] 4.2.2 Ensure that the --authorization-mode argument is not set to AlwaysAllow (Automated)

== Remediations node ==
4.2.1 If using a Kubelet config file, edit the file to set `authentication: anonymous: enabled` to
`false`.
If using executable arguments, edit the kubelet service file
/lib/systemd/system/kubelet.service on each worker node and
set the below parameter in KUBELET_SYSTEM_PODS_ARGS variable.
`--anonymous-auth=false`
Based on your system, restart the kubelet service. For example,
systemctl daemon-reload
systemctl restart kubelet.service

4.2.2 If using a Kubelet config file, edit the file to set `authorization.mode` to Webhook. If
using executable arguments, edit the kubelet service file
/lib/systemd/system/kubelet.service on each worker node and
set the below parameter in KUBELET_AUTHZ_ARGS variable.
--authorization-mode=Webhook
Based on your system, restart the kubelet service. For example,
systemctl daemon-reload
systemctl restart kubelet.service
```

We can see the config file of kubelet looking for `--config=` in a `ps` :

```
$ ps aux | grep kubelet | grep config
root        7277  3.4  4.1 2192912 83164 ?       Ssl  10:21   5:32 /usr/bin/kubelet --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --config=/var/lib/kubelet/config.yaml 
```


And in `/var/lib/kubelet/config.yaml` :

```yaml
authentication:
  anonymous:
    enabled: true
  ...
authorization:
  mode: AlwaysAllow
```

⚠️  We may be tempted to change the values here. But for the Kubelet, it's a bit more *tricky*. Indeed, the lab statement tells us that our modifications must resist a `kubeadm upgrade`, yet if we make the modifications in `/var/lib/kubelet/config.yaml`, they will be overwritten by a kubelet update.

⚠️  A cluster created with Kubeadm will have a *ConfigMap* named `kubelet-config` in Namespace kube-system. This ConfigMap will be used if new Nodes are added to the cluster. There is information about that process in the doc https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-reconfigure/#applying-kubelet-configuration-changes (see *Reflecting the kubelet changes* section)

Let's edit that *ConfigMap* and perform the requested changes:

```
$ k -n kube-system edit cm kubelet-config 
```

```yaml
# Please edit the object below. Lines beginning with a '#' will be ignored,
# and an empty file will abort the edit. If an error occurs while saving this file will be
# reopened with the relevant failures.
#
apiVersion: v1
data:
  kubelet: |
    apiVersion: kubelet.config.k8s.io/v1beta1
    authentication:
      anonymous:
        enabled: false          # <--- WE CHANGE HERE true to false
      webhook:
        cacheTTL: 0s
        enabled: true
      x509:
        clientCAFile: /etc/kubernetes/pki/ca.crt
    authorization:
      mode: Webhook             # <--- WE CHANGE HERE AlwaysAllow to Webhook (ie to ask the Kube-apiserver)
      webhook:
        cacheAuthorizedTTL: 0s
        cacheUnauthorizedTTL: 0s
    cgroupDriver: systemd
    clusterDNS:
    - 10.96.0.10
    clusterDomain: cluster.local
    containerRuntimeEndpoint: ""
 ...
```

Now the kubelet configmap is modified, we can see in the docs :

*Run* `kubeadm upgrade node phase kubelet-config` *to download the latest kubelet-config ConfigMap contents into the local file /var/lib/kubelet/config.yaml*

Let's check the help :

```
$ kubeadm upgrade node --help
Upgrade commands for a node in the cluster

The "node" command executes the following phases:

preflight       Run upgrade node pre-flight checks
control-plane   Upgrade the control plane instance deployed on this node, if any
kubelet-config  Upgrade the kubelet configuration for this node
addon           Upgrade the default kubeadm addons
  /coredns        Upgrade the CoreDNS addon
  /kube-proxy     Upgrade the kube-proxy addon
post-upgrade    Run post upgrade tasks

Usage:
  kubeadm upgrade node [flags]
  kubeadm upgrade node [command]

Available Commands:
  phase       Use this command to invoke single phase of the "node" workflow

...
Flags:
 ...
 --dry-run                           Do not change any state, just output the actions that would be performed.
...
```

⚠️ So we run `kubeadm upgrade node phase kubelet-config` but in *dry-run* mode, just to see there is no errors :

```
$ sudo kubeadm upgrade node phase kubelet-config --dry-run | head -10
[dryrun] Creating a real client from "/etc/kubernetes/admin.conf"
[upgrade] Reading configuration from the "kubeadm-config" ConfigMap in namespace "kube-system"...
[upgrade] Use 'kubeadm init phase upload-config --config your-config.yaml' to re-upload it.
[dryrun] Would perform action GET on resource "configmaps" in API group "core/v1"
[dryrun] Resource name "kubeadm-config", namespace "kube-system"
[dryrun] Attached object:
apiVersion: v1
data:
  ClusterConfiguration: |
    apiServer: {}
```

Ok there is no errors.

We can run it :

```
[upgrade] Reading configuration from the "kubeadm-config" ConfigMap in namespace "kube-system"...
[upgrade] Use 'kubeadm init phase upload-config --config your-config.yaml' to re-upload it.
W0417 13:31:44.828179   20972 postupgrade.go:117] Using temporary directory /etc/kubernetes/tmp/kubeadm-kubelet-config2515410998 for kubelet config. To override it set the environment variable KUBEADM_UPGRADE_DRYRUN_DIR
[upgrade] Backing up kubelet config file to /etc/kubernetes/tmp/kubeadm-kubelet-config2515410998/config.yaml
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[upgrade/kubelet-config] The kubelet configuration for this node was successfully upgraded!
```

We can see that the `/var/lib/kubelet/config.yaml` has been updated, so we check its content :

```yaml
authentication:
  anonymous:
    enabled: false
...
authorization:
  mode: Webhook
```

It's just fine ! Now restart the kubelet service :

```
$ sudo systemctl restart kubelet
```

And run the test again :

```
$ sudo kube-bench run --version 1.32 -c "4.2.1,4.2.2"
...

[INFO] 4 Worker Node Security Configuration
[INFO] 4.2 Kubelet
[PASS] 4.2.1 Ensure that the --anonymous-auth argument is set to false (Automated)
[PASS] 4.2.2 Ensure that the --authorization-mode argument is not set to AlwaysAllow (Automated)
```

✅ Test passes.

## 🏁 Final Validation

Ok everything is fine, just for fun, we can run the whole tests :

```
$ sudo kube-bench run --version 1.32 --noremediations -c "1.1.11,1.2.6,1.2.7,1.2.8,1.2.15,1.2.22,1.2.23,1.2.24,1.3.2,1.4.1,2.1,2.2,4.2.1,4.2.2,4.2.11"
Warning: Kubernetes version was not auto-detected because kubectl could not connect to the Kubernetes server. This may be because the kubeconfig information is missing or has credentials that do not match the server. Assuming default version 1.18
[INFO] 1 Control Plane Security Configuration
[INFO] 1.1 Control Plane Node Configuration Files
[PASS] 1.1.11 Ensure that the etcd data directory permissions are set to 700 or more restrictive (Automated)
[INFO] 1.2 API Server
[PASS] 1.2.6 Ensure that the --authorization-mode argument is not set to AlwaysAllow (Automated)
[PASS] 1.2.7 Ensure that the --authorization-mode argument includes Node (Automated)
[PASS] 1.2.8 Ensure that the --authorization-mode argument includes RBAC (Automated)
[PASS] 1.2.15 Ensure that the --profiling argument is set to false (Automated)
[PASS] 1.2.22 Ensure that the --service-account-key-file argument is set as appropriate (Automated)
[PASS] 1.2.23 Ensure that the --etcd-certfile and --etcd-keyfile arguments are set as appropriate (Automated)
[PASS] 1.2.24 Ensure that the --tls-cert-file and --tls-private-key-file arguments are set as appropriate (Automated)
[INFO] 1.3 Controller Manager
[PASS] 1.3.2 Ensure that the --profiling argument is set to false (Automated)
[INFO] 1.4 Scheduler
[PASS] 1.4.1 Ensure that the --profiling argument is set to false (Automated)

== Summary master ==
10 checks PASS
0 checks FAIL
0 checks WARN
0 checks INFO

[INFO] 2 Etcd Node Configuration
[INFO] 2 Etcd Node Configuration
[PASS] 2.1 Ensure that the --cert-file and --key-file arguments are set as appropriate (Automated)
[PASS] 2.2 Ensure that the --client-cert-auth argument is set to true (Automated)

== Summary etcd ==
2 checks PASS
0 checks FAIL
0 checks WARN
0 checks INFO

[INFO] 3 Control Plane Configuration

== Summary controlplane ==
0 checks PASS
0 checks FAIL
0 checks WARN
0 checks INFO

[INFO] 4 Worker Node Security Configuration
[INFO] 4.2 Kubelet
[PASS] 4.2.1 Ensure that the --anonymous-auth argument is set to false (Automated)
[PASS] 4.2.2 Ensure that the --authorization-mode argument is not set to AlwaysAllow (Automated)
[PASS] 4.2.11 Verify that the RotateKubeletServerCertificate argument is set to true (Manual)

== Summary node ==
3 checks PASS
0 checks FAIL
0 checks WARN
0 checks INFO

[INFO] 5 Kubernetes Policies

== Summary policies ==
0 checks PASS
0 checks FAIL
0 checks WARN
0 checks INFO

== Summary total ==
15 checks PASS
0 checks FAIL
0 checks WARN
0 checks INFO
```

🎉 All tests PASS !