# Solution

## 🧠 Understanding the Lab: Stateless & Immutable Pods

In this lab, your goal is to identify and delete **non-compliant Pods** from the `production` namespace based on two key container security best practices: **statelessness** and **immutability**.

---

### 🔍 Definitions & Criteria

#### 📦 **Stateless**

A **stateless Pod** does not persist data locally inside the container filesystem. It should not store any information that is required after the Pod restarts or is rescheduled.

**Non-stateless indicators** (i.e., stateful behavior):
- The use of **`emptyDir`**, **`hostPath`**, or other **writable volumes** inside containers.
- Any volume mount (even `emptyDir`) that is **not readOnly** allows state to be written and persisted during the lifetime of the Pod.

**Examples**:
```yaml
volumes:
  - name: temp
    emptyDir: {}
```

---

#### 🔒 **Immutable**

An **immutable Pod** is one that runs in a locked-down mode with **minimum privileges**. This enhances security and limits the impact in case of compromise.

**Non-immutable indicators**:
- `securityContext.privileged: true`
- `securityContext.allowPrivilegeEscalation: true`
- `securityContext.runAsUser: 0` (running as root user)

**Examples**:
```yaml
securityContext:
  privileged: true
```

```yaml
securityContext:
  runAsUser: 0
```

---

### ✅ Compliant Pods Should:

- Avoid all writable volumes unless readOnly is explicitly set.
- Avoid privileged mode and privilege escalation.
- Avoid running as root unless strictly required and justified.

---

### 🚨 What to Delete?

Delete any Pod that meets **any** of the following conditions:
1. Uses a writable volume (e.g. `emptyDir`, `hostPath`, etc.).
2. Has containers with elevated privileges (as described above).

## Pods inspection

```
$ k -n production get pod 
NAME                       READY   STATUS    RESTARTS   AGE
alpine-root                1/1     Running   0          47m
backend-5759bdb6cc-86c9k   1/1     Running   0          47m
cache                      1/1     Running   0          47m
frontend-configmap         1/1     Running   0          47m
frontend-emptydir          1/1     Running   0          47m
nginx-86c57bc6b8-mxhg8     1/1     Running   0          47m
reports-678747bc44-b68dj   1/1     Running   0          47m
```

### alpine-root  

```yaml
$ k -n production get pod/alpine-root -oyaml
...
spec:
  containers:
  - command:
    - sleep
    - "3600"
    image: alpine
    imagePullPolicy: Always
    name: app
    resources: {}
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
    volumeMounts:
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: kube-api-access-92dkv
      readOnly: true

  securityContext:
    runAsUser: 0                # RUN AS ROOT
  serviceAccount: default
  serviceAccountName: default
...
  volumes:
  - name: kube-api-access-92dkv
    projected:
      defaultMode: 420
      sources:
      - serviceAccountToken:
          expirationSeconds: 3607
          path: token
      - configMap:
          items:
          - key: ca.crt
            path: ca.crt
          name: kube-root-ca.crt
      - downwardAPI:
          items:
          - fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
            path: namespace
```

- ❌ `runAsUser: 0` → **Runs as root** (not immutable)
- ✔ No volumes used (stateless)
- Not part of a deployment

**Action**: delete it
```bash
kubectl delete pod alpine-root -n production
```

### backend-5759bdb6cc-86c9k

```yaml
$ k -n production get pod/backend-5759bdb6cc-86c9k -oyaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: "2025-04-17T15:53:01Z"
  generateName: backend-5759bdb6cc-
  labels:
    app: backend
    pod-template-hash: 5759bdb6cc
  name: backend-5759bdb6cc-86c9k
  namespace: production
  ownerReferences:   # POD IN A DEPLOYEMENT
  - apiVersion: apps/v1
    blockOwnerDeletion: true
    controller: true
    kind: ReplicaSet
    name: backend-5759bdb6cc
    uid: 07680ac1-c8a3-4a64-a807-3c9983c5a47d
  resourceVersion: "35855"
  uid: a3bcce23-25b7-4886-907f-e2e11ce60870
spec:
  containers:
  - image: nginx
    imagePullPolicy: Always
    name: backend
    resources: {}
    securityContext:
      privileged: true   # PRIVILEDGE
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
    volumeMounts:
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: kube-api-access-cbns8
      readOnly: true
  dnsPolicy: ClusterFirst
  enableServiceLinks: true
  nodeName: k8s-node01
  preemptionPolicy: PreemptLowerPriority
  priority: 0
  restartPolicy: Always
  schedulerName: default-scheduler
  securityContext: {}
  serviceAccount: default
  serviceAccountName: default
  terminationGracePeriodSeconds: 30
  tolerations:
  - effect: NoExecute
    key: node.kubernetes.io/not-ready
    operator: Exists
    tolerationSeconds: 300
  - effect: NoExecute
    key: node.kubernetes.io/unreachable
    operator: Exists
    tolerationSeconds: 300
  volumes:
  - name: kube-api-access-cbns8
    projected:
      defaultMode: 420
      sources:
      - serviceAccountToken:
          expirationSeconds: 3607
          path: token
      - configMap:
          items:
          - key: ca.crt
            path: ca.crt
          name: kube-root-ca.crt
      - downwardAPI:
          items:
          - fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
            path: namespace
```

- ❌ `privileged: true` → **Privileged mode** (not immutable)
- ✔ No writable volumes (stateless)
- Managed by a Deployment

**Action**: scale down deployment
```bash
kubectl scale deployment backend --replicas 0 -n production
```

### Pod cache

```yaml
$ k -n production get pod/cache -oyaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","kind":"Pod","metadata":{"annotations":{},"name":"cache","namespace":"production"},"spec":{"containers":[{"image":"redis","name":"redis","securityContext":{"readOnlyRootFilesystem":true}}]}}
  creationTimestamp: "2025-04-17T15:53:01Z"
  name: cache
  namespace: production
  resourceVersion: "35898"
  uid: 2f59e692-0407-4a8c-ba43-e06eea945c12
spec:
  containers:
  - image: redis
    imagePullPolicy: Always
    name: redis
    resources: {}
    securityContext:
      readOnlyRootFilesystem: true                ## The ROOT FS is in READ-ONLY
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
    volumeMounts:
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: kube-api-access-hjsgj
      readOnly: true
  dnsPolicy: ClusterFirst
  enableServiceLinks: true
  nodeName: k8s-node01
  preemptionPolicy: PreemptLowerPriority
  priority: 0
  restartPolicy: Always
  schedulerName: default-scheduler
  securityContext: {}                 ## OK
  serviceAccount: default
  serviceAccountName: default
  terminationGracePeriodSeconds: 30
  tolerations:
  - effect: NoExecute
    key: node.kubernetes.io/not-ready
    operator: Exists
    tolerationSeconds: 300
  - effect: NoExecute
    key: node.kubernetes.io/unreachable
    operator: Exists
    tolerationSeconds: 300
  volumes:
  - name: kube-api-access-hjsgj
    projected:
      defaultMode: 420
      sources:
      - serviceAccountToken:
          expirationSeconds: 3607
          path: token
      - configMap:
          items:
          - key: ca.crt
            path: ca.crt
          name: kube-root-ca.crt
      - downwardAPI:
          items:
          - fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
            path: namespace
```

- ✔ `readOnlyRootFilesystem: true`
- ✔ No volume mounts

**Action**: compliant ✅

### Pod frontend-configmap

```yaml
$ k -n production get pod frontend-configmap -oyaml
...
spec:
  containers:
  - image: nginx
    imagePullPolicy: Always
    name: nginx
    resources: {}
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
    volumeMounts:
    - mountPath: /etc/config
      name: config
      readOnly: true
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: kube-api-access-6kcvq
      readOnly: true
  dnsPolicy: ClusterFirst
  enableServiceLinks: true
  nodeName: k8s-node01
  preemptionPolicy: PreemptLowerPriority
  priority: 0
  restartPolicy: Always
  schedulerName: default-scheduler
  securityContext: {}
  serviceAccount: default
  serviceAccountName: default
  terminationGracePeriodSeconds: 30
  ...
  volumes:
  - configMap:
      defaultMode: 420
      name: app-config
    name: config
  - name: kube-api-access-6kcvq
    projected:
      defaultMode: 420
      sources:
      - serviceAccountToken:
          expirationSeconds: 3607
          path: token
      - configMap:
          items:
          - key: ca.crt
            path: ca.crt
          name: kube-root-ca.crt
      - downwardAPI:
          items:
          - fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
            path: namespace
``` 

- ✔ Volume mount is from a ConfigMap, and is read-only
- ✔ No privileged settings

**Action**: compliant ✅

## Pod frontend-emptydir

```yaml
$ k -n production get pod frontend-emptydir -oyaml
...
spec:
  containers:
  - image: nginx
    imagePullPolicy: Always
    name: frontend
    resources: {}
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
    volumeMounts:
    - mountPath: /data          ## A MOUNT HERE - IN R/W MODE
      name: data
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: kube-api-access-c9w8n
      readOnly: true
  dnsPolicy: ClusterFirst
  enableServiceLinks: true
  nodeName: k8s-node01
  preemptionPolicy: PreemptLowerPriority
  priority: 0
  restartPolicy: Always
  schedulerName: default-scheduler
  securityContext: {}
  serviceAccount: default
  serviceAccountName: default
  terminationGracePeriodSeconds: 30
  tolerations:
  - effect: NoExecute
    key: node.kubernetes.io/not-ready
    operator: Exists
    tolerationSeconds: 300
  - effect: NoExecute
    key: node.kubernetes.io/unreachable
    operator: Exists
    tolerationSeconds: 300
  volumes:
  - emptyDir: {}         # EMPTY DIR VOLUME
    name: data
  - name: kube-api-access-c9w8n
    projected:
      defaultMode: 420
      sources:
      - serviceAccountToken:
          expirationSeconds: 3607
          path: token
      - configMap:
          items:
          - key: ca.crt
            path: ca.crt
          name: kube-root-ca.crt
      - downwardAPI:
          items:
          - fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
            path: namespace

```

- ❌ Has an `emptyDir` volume mounted with default (read-write) mode
- ✔ No elevated privileges

**Action**: delete it
```bash
kubectl delete pod frontend-emptydir -n production
```

### Pod nginx-86c57bc6b8-mxhg8

```yaml 
$ k -n production get pod/nginx-86c57bc6b8-mxhg8 -oyaml
...
  ownerReferences:
  - apiVersion: apps/v1
    blockOwnerDeletion: true
    controller: true
    kind: ReplicaSet
    name: nginx-86c57bc6b8
    uid: c2b0e412-4ec0-4b93-91e2-ecba1a1b3efb
  resourceVersion: "35879"
  uid: a1b93aca-4d71-476f-b6fd-9b11a0d4e90e
spec:
  containers:
  - image: nginx
    imagePullPolicy: Always
    name: nginx
    ports:
    - containerPort: 80
      protocol: TCP
    resources: {}
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
    volumeMounts:
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: kube-api-access-kjgvx
      readOnly: true
  dnsPolicy: ClusterFirst
  enableServiceLinks: true
  nodeName: k8s-node01
  preemptionPolicy: PreemptLowerPriority
  priority: 0
  restartPolicy: Always
  schedulerName: default-scheduler
  securityContext: {}
  serviceAccount: default
  serviceAccountName: default
  terminationGracePeriodSeconds: 30
  tolerations:
  - effect: NoExecute
    key: node.kubernetes.io/not-ready
    operator: Exists
    tolerationSeconds: 300
  - effect: NoExecute
    key: node.kubernetes.io/unreachable
    operator: Exists
    tolerationSeconds: 300
  volumes:
  - name: kube-api-access-kjgvx
    projected:
      defaultMode: 420
      sources:
      - serviceAccountToken:
          expirationSeconds: 3607
          path: token
      - configMap:
          items:
          - key: ca.crt
            path: ca.crt
          name: kube-root-ca.crt
      - downwardAPI:
          items:
          - fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
            path: namespace

```

❌ Issue: Pod is **not immutable**

Even though the Pod:

* Does **not use `emptyDir` or `hostPath`** volumes (✅ stateless),
* Does **not run in privileged mode**,

…it still **does not meet immutability standards**.

⚠️ Missing `securityContext` hardening

* `readOnlyRootFilesystem` is **not set** → the container can write to the root filesystem.
* `allowPrivilegeEscalation` is **not explicitly disabled**.
* There's **no `runAsNonRoot: true` or `runAsUser` specified**, so it may fall back to root depending on the image.

Even if the official `nginx` image runs as UID 101, this is not guaranteed across variants (like `nginx:alpine`, `nginx:distroless`, etc.).

**Improvement approach**: Patch the Deployment to make it immutable by adding this to the container's `securityContext`:

```yaml
securityContext:
  runAsUser: 101
  runAsNonRoot: true
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
```

### Pod reports-678747bc44-b68dj

```yaml 
$ k -n production get pod/reports-678747bc44-b68dj -oyaml
...
  ownerReferences:
  - apiVersion: apps/v1
    blockOwnerDeletion: true
    controller: true
    kind: ReplicaSet
    name: reports-678747bc44
    uid: 90ad04e8-1486-453e-bebc-902272137690
  resourceVersion: "42735"
  uid: f5cfee5c-6939-48ff-b518-23f2ed45b728
spec:
  containers:
  - command:
    - sleep
    - "3600"
    image: busybox
    imagePullPolicy: Always
    name: reports
    resources: {}
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
    volumeMounts:
    - mountPath: /data         # MOUNT IN READONLY
      name: temp-storage
      readOnly: true
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: kube-api-access-tgff5
      readOnly: true
  dnsPolicy: ClusterFirst
  enableServiceLinks: true
  nodeName: k8s-controlplane
  preemptionPolicy: PreemptLowerPriority
  priority: 0
  restartPolicy: Always
  schedulerName: default-scheduler
  securityContext: {}
  serviceAccount: default
  serviceAccountName: default
  terminationGracePeriodSeconds: 30
  tolerations:
  - effect: NoExecute
    key: node.kubernetes.io/not-ready
    operator: Exists
    tolerationSeconds: 300
  - effect: NoExecute
    key: node.kubernetes.io/unreachable
    operator: Exists
    tolerationSeconds: 300
  volumes:
  - emptyDir: {}             # EMPTYDIR VOLUME
    name: temp-storage
  - name: kube-api-access-tgff5
    projected:
      defaultMode: 420
      sources:
      - serviceAccountToken:
          expirationSeconds: 3607
          path: token
      - configMap:
          items:
          - key: ca.crt
            path: ca.crt
          name: kube-root-ca.crt
      - downwardAPI:
          items:
          - fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
            path: namespace
```

- ⚠️ Uses `emptyDir` mounted as read-only, but `emptyDir` implies ephemeral state — still considered stateful
- ✔ No elevated privileges

**Action**: non compliant ❌ 

```
kubectl delete pod/reports-678747bc44-b68dj -n production
```

## 📊 Summary Table

| Pod Name              | Stateless | Immutable | Action          |
|----------------------|-----------|-----------|-----------------|
| `alpine-root`        | ✅        | ❌        | Delete pod      |
| `backend`            | ✅        | ❌        | Scale to 0      |
| `frontend-emptydir`  | ❌        | ✅        | Delete pod      |
| `cache`              | ✅        | ✅        | Keep            |
| `frontend-configmap` | ✅        | ✅        | Keep            |
| `reports`            | ❌        | ✅        | Scale to 0      |
| `nginx`              | ✅        | ❌        | Scale to 0      |

---

## 🔗 References

- 📘 https://kubernetes.io/docs/concepts/security/pod-security-standards/
- 📄 Pod Security Context: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/

---

🎉 Good job! All non-compliant Pods are handled.

This approach is systematic, secure, and exactly the kind of reasoning expected during the CKS exam.

## Script

A script using *jq* :

```sh
#!/bin/bash

echo "🔍 Searching for non-stateless or non-immutable Pods in namespace 'production'..."
kubectl get pods -n production -o json | jq -r '
  .items[] |
  select(
    (.spec.volumes[]?.emptyDir? or .spec.volumes[]?.hostPath?) or
    (.spec.containers[]?.securityContext?.privileged == true) or
    (.spec.containers[]?.securityContext?.allowPrivilegeEscalation == true) or
    (.spec.containers[]?.securityContext?.runAsUser == 0)
  ) |
  .metadata.name
'
```

```
$ ./list-violating-pods.sh 
🔍 Searching for non-stateless or non-immutable Pods in namespace 'production'...
backend-5759bdb6cc-lw255
frontend-emptydir
reports-678747bc44-b68dj
```



