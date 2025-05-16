# Solution: Enforcing ReadOnly Root Filesystem in Kubernetes Deployment

### ✅ Goal

The objective is to ensure that a container in a Deployment cannot write to its root filesystem, except to the `/tmp` directory.

---

### ⚖️ Steps to Solve

1. **Inspect the original Deployment:**

The Deployment uses the image `busybox:1.32.0` with a command that keeps the container running:

```yaml
command: ['sh', '-c', 'tail -f /dev/null']
```

There is no security context set by default.

What we have to do :
- We add the `readOnlyRootFilesystem: true` property in the **container-level** `securityContext` to prevent writes to the root filesystem.
- We use an `emptyDir` volume and mount it to `/tmp`. `emptyDir` is an ephemeral volume that is recreated on pod restart and writable by default.


```yaml
# immutable-deployment-new.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-deployment
  namespace: team-green
  labels:
    app: app-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app-deployment
  template:
    metadata:
      labels:
        app: app-deployment
    spec:
      containers:
      - name: busybox
        securityContext:                  # ADD
          readOnlyRootFilesystem: true    # ADD
        image: busybox:1.32.0
        imagePullPolicy: IfNotPresent
        command: ['sh', '-c', 'tail -f /dev/null']
        volumeMounts:           # ADD
          - mountPath: /tmp     # ADD
            name: tmp-vol       # ADD
      volumes:                  # ADD
        - name: tmp-vol         # ADD
          emptyDir:             # ADD
            sizeLimit: 10Mi     # ADD
```

4. **Apply changes:**

   Save the modified YAML to `/opt/course/19/immutable-deployment-new.yaml` and redeploy:

```
$ k -n team-green delete deployments.apps app-deployment 
deployment.apps "app-deployment" deleted

$ k create -f /opt/course/19/immutable-deployment-new.yaml
deployment.apps/app-deployment created
```

5. **Verify:**

Exec into the pod and attempt to write files:

```
$ k -n team-green exec -it deployments/app-deployment -- sh
/ # id
uid=0(root) gid=0(root) groups=0(root),10(wheel)
/ # touch /etc/TEST
touch: /etc/TEST: Read-only file system
/ # touch /tmp/TEST
/ # exit
```

### ☑️ Best Practices

* Always limit write access in production to the strict minimum.
* A `readOnlyRootFilesystem` is a powerful security control that can prevent many classes of attacks.
* Ensure that applications can tolerate running in a readonly root context or provide necessary writable mounts (e.g. `/tmp`, logs).

---

### 🔗 References

* Kubernetes documentation: [SecurityContext](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-container)
* Kubernetes documentation: [emptyDir volume](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir)
