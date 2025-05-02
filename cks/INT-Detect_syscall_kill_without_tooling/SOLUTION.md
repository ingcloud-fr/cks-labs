## Solution: Detect Syscall Kill Without Tooling

In this scenario, we must detect a suspicious use of the `kill` syscall among several Pods, without using monitoring tools like Falco or Tracee. We'll investigate manually using process inspection.

---

### 1. Identify which Pods run on which nodes.

```bash
$ kubectl get pods -n production -o wide
NAME                     READY   STATUS    RESTARTS   AGE   IP           NODE         NOMINATED NODE   READINESS GATES
app-a-598847b6b8-wmthb   1/1     Running   0          17s   10.0.1.100   k8s-node01   <none>           <none>
app-b-7cdc44b5bd-4bztc   1/1     Running   0          17s   10.0.1.29    k8s-node01   <none>           <none>
app-c-5b4d6f66c7-94j6w   1/1     Running   0          17s   10.0.1.237   k8s-node01   <none>           <none>
app-d-58497b9975-zwcqw   1/1     Running   0          17s   10.0.1.174   k8s-node01   <none>           <none>
```
📌 All the Pods in the namespace `production` run on k8s-node01

---

### 2. SSH into node01

Let's connect on k8s-node01 :

```bash
$ ssh vagrant@k8s-node01
$ sudo -i
```



### 3. Use crictl to find container IDs for each Pod
```
# crictl pods --namespace production
POD ID              CREATED             STATE               NAME                     NAMESPACE           ATTEMPT             RUNTIME
587286bd755ed       2 minutes ago       Ready               app-a-598847b6b8-wmthb   production          0                   (default)
d41de099de0b9       2 minutes ago       Ready               app-b-7cdc44b5bd-4bztc   production          0                   (default)
d655a125d67cd       2 minutes ago       Ready               app-c-5b4d6f66c7-94j6w   production          0                   (default)
9c2ef6eb478a6       2 minutes ago       Ready               app-d-58497b9975-zwcqw   production          0                   (default)
```
> Note the pod IDs (POD ID) of each running pod.

Then for each pod ID, we note the container ID :

```
# crictl ps --pod <POD_ID>
```

```
# crictl ps --pod 587286bd755ed
CONTAINER           IMAGE               CREATED             STATE               NAME                ATTEMPT             POD ID              POD                      NAMESPACE
47680b119c11c       ff7a7936e9306       4 minutes ago       Running             app                 0                   587286bd755ed       app-a-598847b6b8-wmthb   production

# crictl ps --pod d41de099de0b9
CONTAINER           IMAGE               CREATED             STATE               NAME                ATTEMPT             POD ID              POD                      NAMESPACE
f2aa7f5e5b308       ff7a7936e9306       4 minutes ago       Running             app                 0                   d41de099de0b9       app-b-7cdc44b5bd-4bztc   production

# crictl ps --pod d655a125d67cd
CONTAINER           IMAGE               CREATED             STATE               NAME                ATTEMPT             POD ID              POD                      NAMESPACE
8f75b518448f2       ff7a7936e9306       4 minutes ago       Running             app                 0                   d655a125d67cd       app-c-5b4d6f66c7-94j6w   production

# crictl ps --pod 9c2ef6eb478a6
CONTAINER           IMAGE               CREATED             STATE               NAME                ATTEMPT             POD ID              POD                      NAMESPACE
0a8c0e5096513       ff7a7936e9306       4 minutes ago       Running             app                 0                   9c2ef6eb478a6       app-d-58497b9975-zwcqw   production

```

### 4. Inspect the container and find process name

```
# crictl inspect <CONTAINER_ID> | grep args -A2
```

We inspect the Pods ID in order to get their pid :

```
# crictl inspect 47680b119c11c | grep pid
            "pid": 1
    "pid": 50521,
            "type": "pid"

# crictl inspect f2aa7f5e5b308 | grep pid
            "pid": 1
    "pid": 50487,
            "type": "pid"

# crictl inspect 8f75b518448f2 | grep pid
            "pid": 1
    "pid": 50453,
            "type": "pid"

# crictl inspect 0a8c0e5096513 | grep pid
            "pid": 1
    "pid": 50419,
            "type": "pid"

```

```
```

```
```


```
```



> You should see the command or binary run in that container (in our case: `app`)

---

### 5. Use ps to list PIDs
```bash
ps aux | grep app
```
> Match with the binary you found earlier. Identify suspicious processes.

---

### 6. Use strace to trace syscalls

We use strace to inspect suspicious activities.

No suspicious activities on the first three processes :


```
# strace -p 50521
strace: Process 50521 attached
wait4(-1, [{WIFEXITED(s) && WEXITSTATUS(s) == 0}], 0, NULL) = 55
--- SIGCHLD {si_signo=SIGCHLD, si_code=CLD_EXITED, si_pid=55, si_uid=0, si_status=0, si_utime=0, si_stime=0} ---
rt_sigreturn({mask=[]})                 = 55
wait4(-1, 0x7fff6947827c, WNOHANG, NULL) = -1 ECHILD (No child processes)
write(1, "App A running\n", 14)         = 14
clone(child_stack=NULL, flags=CLONE_CHILD_CLEARTID|CLONE_CHILD_SETTID|SIGCHLD, child_tidptr=0x7f9da89bfa10) = 56
wait4(-1, ^Cstrace: Process 50521 detached
 <detached ...>
```

```
# strace -p 50487
strace: Process 50487 attached
wait4(-1, [{WIFEXITED(s) && WEXITSTATUS(s) == 0}], 0, NULL) = 56
--- SIGCHLD {si_signo=SIGCHLD, si_code=CLD_EXITED, si_pid=56, si_uid=0, si_status=0, si_utime=0, si_stime=0} ---
rt_sigreturn({mask=[]})                 = 56
wait4(-1, 0x7ffd9897e61c, WNOHANG, NULL) = -1 ECHILD (No child processes)
write(1, "App B working\n", 14)         = 14
clone(child_stack=NULL, flags=CLONE_CHILD_CLEARTID|CLONE_CHILD_SETTID|SIGCHLD, child_tidptr=0x7f27412a5a10) = 57
wait4(-1, ^Cstrace: Process 50487 detached
 <detached ...>

```

```
# strace -p 50453
strace: Process 50453 attached
wait4(-1, [{WIFEXITED(s) && WEXITSTATUS(s) == 0}], 0, NULL) = 57
--- SIGCHLD {si_signo=SIGCHLD, si_code=CLD_EXITED, si_pid=57, si_uid=0, si_status=0, si_utime=0, si_stime=0} ---
rt_sigreturn({mask=[]})                 = 57
wait4(-1, 0x7fff28acc11c, WNOHANG, NULL) = -1 ECHILD (No child processes)
write(1, "App C doing work\n", 17)      = 17
clone(child_stack=NULL, flags=CLONE_CHILD_CLEARTID|CLONE_CHILD_SETTID|SIGCHLD, child_tidptr=0x7f6dce3b2a10) = 58
wait4(-1, ^Cstrace: Process 50453 detached
 <detached ...>

```

But the last one :

```
# strace -p 50419
strace: Process 50419 attached
wait4(-1, [{WIFEXITED(s) && WEXITSTATUS(s) == 0}], 0, NULL) = 175
--- SIGCHLD {si_signo=SIGCHLD, si_code=CLD_EXITED, si_pid=175, si_uid=0, si_status=0, si_utime=0, si_stime=0} ---
rt_sigreturn({mask=[]})                 = 175
wait4(-1, 0x7ffc57ab7eac, WNOHANG, NULL) = -1 ECHILD (No child processes)
getpid()                                = 1
kill(666, SIGTERM)                      = -1 ESRCH (No such process)
write(2, "sh: can't kill pid 666: No such "..., 40) = 40
clone(child_stack=NULL, flags=CLONE_CHILD_CLEARTID|CLONE_CHILD_SETTID|SIGCHLD, child_tidptr=0x7f24613d4a10) = 176
wait4(-1, [{WIFEXITED(s) && WEXITSTATUS(s) == 0}], 0, NULL) = 176
--- SIGCHLD {si_signo=SIGCHLD, si_code=CLD_EXITED, si_pid=176, si_uid=0, si_status=0, si_utime=0, si_stime=0} ---
rt_sigreturn({mask=[]})                 = 176
wait4(-1, 0x7ffc57ab7eac, WNOHANG, NULL) = -1 ECHILD (No child processes)
getpid()                                = 1
kill(666, SIGTERM)                      = -1 ESRCH (No such process)
write(2, "sh: can't kill pid 666: No such "..., 40) = 40
clone(child_stack=NULL, flags=CLONE_CHILD_CLEARTID|CLONE_CHILD_SETTID|SIGCHLD, child_tidptr=0x7f24613d4a10) = 177
wait4(-1, ^Cstrace: Process 50419 detached
 <detached ...>

```

This process is trying to send kills !

---

### 7. Scale down the faulty Deployment


This PID 50419 is linked to ContainerID 0a8c0e5096513 whi is linked to PodID 9c2ef6eb478a6 ie pod named app-d-58497b9975-zwcqw.


```
kubectl -n production scale deploy app-d --replicas=0
```



### ✅ Tips
- `strace` is your best friend here for real-time syscall tracing.
- Use `crictl` to map Pods -> Containers -> PIDs.
- Use `kubectl get pods -o wide` to know where each Pod runs.

---

### 🔒 In Real-World Scenarios
- This technique is powerful but manual.
- In production environments, tools like Tracee, eBPF probes or Falco would alert you automatically.
- Restricting `kill` can also be done via Seccomp profiles.

---

### 📚 Resources
- https://man7.org/linux/man-pages/man2/syscalls.2.html
- https://strace.io/
- https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/

