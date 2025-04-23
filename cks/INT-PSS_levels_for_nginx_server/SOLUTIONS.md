# ✅ Solution – Pod Security Standards: green, orange, red

This document explains the reasoning, expected observations, and minimal changes required to make each `nginx` Deployment work under the assigned Pod Security Standard (PSS) level.

Docs: search for "PSA" in official documentation
- https://kubernetes.io/docs/concepts/security/pod-security-admission/
- The link to PSS is just above in the left menu : https://kubernetes.io/docs/concepts/security/pod-security-standards/
---

## 🟢 Namespace: `green` – PSS `baseline`, `warn` mode

Apply the label:
```bash
$ kubectl label ns team-green pod-security.kubernetes.io/warn=baseline
namespace/team-green labeled
```

We can see the labels on the *team-green* namespace :

```k get ns --show-labels 
NAME              STATUS   AGE     LABELS
team-green        Active   11m   kubernetes.io/metadata.name=team-green,pod-security.kubernetes.io/warn=baseline
```

We delete and re-apply the deployment :

```
$ k -n team-green delete deploy/nginx 
deployment.apps "nginx" deleted

$ k apply -f manifests/nginx-green.yaml 
Warning: would violate PodSecurity "baseline:latest": hostPath volumes (volume "hostvol"), privileged (container "nginx" must not set securityContext.privileged=true)
deployment.apps/nginx created
```

✅ No changes to the deployment are required.

### 💡 Expected behavior:
Since this level is applied in **warn** mode only:
- The nginx pod **will run**, but warnings will be logged.
- No enforcement or failure occurs.

## 🟠 Namespace: `orange` – PSS `baseline`, `enforce` mode

Apply the label to enforce the Pod Security Standard baseline profile:

```bash
$ k label ns team-orange pod-security.kubernetes.io/enforce=baseline
Warning: existing pods in namespace "team-orange" violate the new PodSecurity enforce level "baseline:latest"
Warning: nginx-78dd4fd545-x8f4r: hostPath volumes, privileged
namespace/team-orange labeled
```

We can see the labels for team-orange namespace :

```
$ k get ns --show-labels 
NAME              STATUS   AGE     LABELS
...
team-orange       Active   7h20m   kubernetes.io/metadata.name=team-orange,pod-security.kubernetes.io/enforce=baseline
```

We delete the deploy and run it again (it does not start - see READY):


```
$ k -n team-orange delete deploy/nginx 
deployment.apps "nginx" deleted

$ k apply -f manifests/nginx-orange.yaml 
Warning: would violate PodSecurity "baseline:latest": hostPath volumes (volume "hostvol"), privileged (container "nginx" must not set securityContext.privileged=true)
deployment.apps/nginx created

$ k -n team-orange get all
NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx   0/1     0            0           50s

NAME                               DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-78dd4fd545   1         0         0       50s
```


### The new manifest

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: team-orange
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx
          securityContext:
            allowPrivilegeEscalation: true # We can leave it (the minimum changes is asked) because nginx runs on UID 101
            privileged: false # CHANGE 
      #     volumeMounts:
      #       - name: hostvol
      #         mountPath: /mnt/host
      # volumes:
      #   - name: hostvol
      #     hostPath:
      #       path: /tmp
```

Notes: 

- The image (nginx) is already running with a non-root UID (nginx uses user **101**), so even if `allowPrivilegeEscalation: true`, Kubernetes doesn't trigger a block, because this field doesn't explicitly contradict the image's behavior.
- No need to set `runAsNonRoot: true` (in this exemple, it can run with `runAsNonRoot: false` ) because the nginx image is already running with a non-root UID (like nginx:latest which runs with `UID 101`), so not setting it, or setting false, is tolerated.


Once these changes are applied, the Deployment in the `team-orange` namespace should successfully launch under enforced `baseline` PSS.

To verify:
```
$ k apply -f manifests/nginx-orange.yaml 
deployment.apps/nginx configured

$ k -n team-orange get all
NAME                        READY   STATUS    RESTARTS   AGE
pod/nginx-d67df645f-gbx6f   1/1     Running   0          2m15s

NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx   1/1     1            1           19m

NAME                               DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-776fc55498   0         0         0       2m32s
replicaset.apps/nginx-78dd4fd545   0         0         0       19m
replicaset.apps/nginx-d67df645f    1         1         1       2m15s
```

You should see a running nginx pod without any PSS-related issues.

### Note

A regular nginx image run throuht the *baseline* PSS :

```yaml
$ k -n team-orange run nginx-baseline --image nginx --dry-run=client -o yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: nginx-baseline
  name: nginx-baseline
  namespace: team-orange
spec:
  containers:
  - image: nginx
    name: nginx-baseline
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```
```
$ k -n team-orange run nginx-baseline --image nginx
pod/nginx-baseline created

$ k -n team-orange delete pod/nginx-baseline 
pod "nginx-baseline" deleted
```


## 🔴 Namespace: `red` – PSS `restricted`, `enforce` mode

### 🔍 Objective:
Apply the label:
```bash
$ kubectl label ns team-red pod-security.kubernetes.io/enforce=restricted
Warning: existing pods in namespace "team-red" violate the new PodSecurity enforce level "restricted:latest"
Warning: nginx-78dd4fd545-ndh4f: privileged, allowPrivilegeEscalation != false, unrestricted capabilities, restricted volume types, runAsNonRoot != true, seccompProfile
namespace/team-red labeled

```

### 🧪 What fails and why?
`restricted` mode is stricter and includes all `baseline` rules **plus**:

| ❌ Violation                              | 📌 Explanation                                                                 |
|-------------------------------------------|--------------------------------------------------------------------------------|
| `privileged`                              | Must not be `true` under `restricted` policy                                  |
| `allowPrivilegeEscalation != false`       | Must be explicitly set to `false`                                             |
| `unrestricted capabilities`               | All capabilities must be dropped (`capabilities.drop: ["ALL"]`)              |
| `restricted volume types`                 | Only certain volume types are allowed (e.g., no `hostPath`)                  |
| `runAsNonRoot != true`                    | Must be explicitly set to `true`                                              |
| `seccompProfile` not set                  | Must be set to `RuntimeDefault`                                               |


So we change `manifest/ngninx-red.yaml` to :

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: team-red
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      securityContext:
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: nginx
          image: nginx
          securityContext:
            allowPrivilegeEscalation: false # Can be in spec
            runAsNonRoot: true # Can be in spec
            privileged: false # Not mandatory here because of allowPrivilegeEscalation=false and nginx image ID 101
            capabilities:
              drop: ["ALL"]
```

```
$ k apply -f nginx-red.yaml 
deployment.apps/nginx configured
```


## 💡 Notes / Best Practices
- PSS levels are best combined with **OPA Gatekeeper** to enforce additional policies.
- `restricted` should be the default for production workloads.
- Prefer using custom `PodSecurityDefaults` in the admission controller in large clusters.
- Use `kubectl explain pod.spec.securityContext` to explore all fields.

---

✅ All three pods should now be running and compliant with their namespace’s PSS level.

