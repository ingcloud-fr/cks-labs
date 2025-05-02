# Solution## Solution: Isolate Team Namespaces with Network Policies

### 🧠 Objective Recap
Ensure that pods in each team namespace (`team-blue`, `team-green`, `team-red`) can only communicate with pods within the same namespace.

###

We have :

```
$ k -n team-green get all
NAME                         READY   STATUS    RESTARTS   AGE
pod/nginx-86c57bc6b8-82fnb   1/1     Running   0          7m30s
pod/pod-green                1/1     Running   0          80s

NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/nginx   ClusterIP   10.98.151.212   <none>        80/TCP    7m30s

NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx   1/1     1            1           7m30s

NAME                               DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-86c57bc6b8   1         1         1       7m30s
```

- Note: the same thing for the 2 other namespaces.

Let's create 3 Pods to test in each namespace :

```
$ k run -n team-blue pod-blue --image curlimages/curl --restart Never --command -- sleep 3600
pod/pod-blue created

$ k run -n team-red pod-red --image curlimages/curl --restart Never --command -- sleep 3600
pod/pod-red created

$ k run -n team-green pod-green --image curlimages/curl --restart Never --command -- sleep 3600
pod/pod-green created
```

Let's test :

```
$ k -n team-green exec pod/pod-green -it -- sh
~ $ curl nginx:80
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
~ $ curl nginx.team-red:80
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
```
- Note: the same thing for the 2 other namespaces.

### 🔐 NetworkPolicy: allow ingress only from same namespace

This policy is to be applied once per namespace.
You can use the exact same YAML file with a `kubectl apply -n <namespace> -f <file>`.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-same-namespace-only
spec:
  podSelector:
    matchLabels:
      app: nginx
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: {}
```

### 💡 Explanation
- `podSelector: {}` inside `from:` selects any pod **within the same namespace**.
- No `namespaceSelector` is used, so traffic from other namespaces is implicitly denied.
- Since no egress policy is defined, outbound traffic remains unrestricted.

---

### ✅ Apply the policy to each namespace
```bash
$ k apply -n team-green -f allow-same-namespace-only.yaml 
networkpolicy.networking.k8s.io/allow-same-namespace-only created

$ k apply -n team-red -f allow-same-namespace-only.yaml 
networkpolicy.networking.k8s.io/allow-same-namespace-only created

$ k apply -n team-blue -f allow-same-namespace-only.yaml 
networkpolicy.networking.k8s.io/allow-same-namespace-only created
```

---

### 🧪 Test example
Run a busybox pod in each namespace and try to `curl` another namespace's service:

```
$ k -n team-green exec pod/pod-green -it -- sh
~ $ curl nginx:80 --max-time 2
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
~ $ curl nginx.team-red:80 --max-time 2
curl: (28) Connection timed out after 2001 milliseconds

```

Ok !

---

### 📚 References
- [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Best practices: Namespace isolation](https://kubernetes.io/docs/concepts/services-networking/network-policies/#namespace-isolation)

