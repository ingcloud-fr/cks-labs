# Solution: Restrict Syscalls using a Local Seccomp Profile

## 🔧 Step-by-step

- Search for seccomp in Kubernetes documentation : https://kubernetes.io/docs/tutorials/security/seccomp/

### Ensure the profiles are in place

The following files must exist in `/home/vagrant/profile/`:

- `seccomp-deny-unshare.json`
```json
{
  "defaultAction": "SCMP_ACT_ALLOW",
  "syscalls": [
    {
      "names": ["unshare"],
      "action": "SCMP_ACT_ERRNO"
    }
  ]
}
```

- `seccomp-deny-ptrace.json`
```json
{
  "defaultAction": "SCMP_ACT_ALLOW",
  "syscalls": [
    {
      "names": ["ptrace"],
      "action": "SCMP_ACT_ERRNO"
    }
  ]
}
```

Let's check the Kubelet config directory (`--config=xxx`)

```
$ ps aux | grep kubelet | grep config
root        4686  3.7  3.4 2119948 69508 ?       Ssl  Apr23  32:37 /usr/bin/kubelet --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --config=/var/lib/kubelet/config.yaml --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock --pod-infra-container-image=registry.k8s.io/pause:3.10 --node-ip=192.168.1.200
```

We can see `--config=/var/lib/kubelet/config.yaml`

We create the directory `seccomp` and inside the directory `profiles` to put our profiles in :

```
$ sudo mkdir -p /var/lib/kubelet/seccomp/profiles
```

And copy the 2 profiles :

```
$ sudo cp profiles/*.json /var/lib/kubelet/seccomp/profiles
```

**We do the same thing on node01.**

```
$ scp -r profiles/ vagrant@k8s-node01:~
```

```
$ ssh vagrant@k8s-node01
vagrant@k8s-node01:~$ sudo mkdir -p /var/lib/kubelet/seccomp/profiles
vagrant@k8s-node01:~$ sudo cp profiles/*.json /var/lib/kubelet/seccomp/profiles
```


### Block `unshare`

```
$ k run -n team-blue pod-unshare --image ubuntu --dry-run=client -o yaml --command -- unshare --mount --pid --fork --mount-proc bash > pod-unshare.yaml
```

We edit the yaml and add :

```yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod-unshare
  name: pod-unshare
  namespace: team-blue
spec:
  securityContext:            # ADD
    seccompProfile:           # ADD
      type: Localhost         # ADD
      localhostProfile: profiles/seccomp-deny-unshare.json # ADD
  containers:
  - command:
    - unshare
    - --mount
    - --pid
    - --fork
    - --mount-proc
    - bash
    image: ubuntu
    name: test-unshare
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}

```

And apply it:
```bash
kubectl apply -f pod-unshare.yaml
```

Check the logs:

```bash
$ k -n team-blue logs pod-unshare 
unshare: unshare failed: Operation not permitted
```
✅ Ok ! 

### Block `ptrace` (e.g. using `strace`)

```
$ k -n team-blue run pod-ptrace --image ubuntu --dry-run=client -o yaml --command -- sleep 3600 > pod-ptrace.yaml
```

We edit `pod-ptrace.yaml` and add the seccomp profile :

```yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod-ptrace
  name: pod-ptrace
  namespace: team-blue
spec:
  securityContext:         # ADD
    seccompProfile:        # ADD
      type: Localhost      # ADD
      localhostProfile: profiles/seccomp-deny-ptrace.json # ADD
  containers:
  - command:
    - sleep
    - "3600"
    image: ubuntu
    name: pod-ptrace
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

Save this as `pod-ptrace.yaml` and apply it:
```bash
kubectl apply -f pod-ptrace.yaml
```

Than we apply :

```$ k apply -f pod-ptrace.yaml 
pod/pod-ptrace created
```

We log into the pod :

```
$ k -n team-blue exec -it pod/pod-ptrace -- bash
```

We install `strace` and test :

```
root@pod-ptrace:/# apt-get update
...                                                                                                                                     root@pod-ptrace:/# apt-get install strace -y
...
root@pod-ptrace:/# strace ls
strace: test_ptrace_get_syscall_info: PTRACE_TRACEME: Operation not permitted
strace: ptrace(PTRACE_TRACEME, ...): Operation not permitted
strace: PTRACE_SETOPTIONS: Operation not permitted
strace: cleanup: waitpid(-1, __WALL): No child processes

```
We see an error such as:
```
strace: ptrace(PTRACE_TRACEME, ...): Operation not permitted
```

✅  This confirms that `ptrace` was successfully blocked.

---

## 🧠 What does `unshare` do?
The `unshare` command allows a process to disassociate parts of its execution context, such as mount, UTS, IPC, network, PID, and user namespaces. It is often used to create isolated environments or containers manually. Blocking it prevents the container from attempting to escape or isolate parts of its execution environment.

## 🧠 What does `ptrace` do?
The `ptrace` syscall is used primarily for debugging: it allows one process to observe and control the execution of another. Tools like `strace` and `gdb` depend on it. Blocking `ptrace` prevents introspection, which is a common security measure to stop reverse engineering or container escape attempts.

## 📚 References
- [Kubernetes official docs: Seccomp](https://kubernetes.io/docs/tutorials/security/seccomp/)


