## Solution: Apply a Default-Deny Ingress Policy with Cilium

### ✅ Goal
Prevent all ingress traffic by default for Pods in the `team-blue` namespace, then verify access.

---

### 🔒 Step 1: Create the Default-Deny Ingress CiliumNetworkPolicy


```
$ k -n team-blue get all --show-labels 
NAME           READY   STATUS    RESTARTS   AGE   LABELS
pod/backend    1/1     Running   0          14s   app=backend
pod/frontend   1/1     Running   0          14s   role=frontend

NAME                  TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE   LABELS
service/backend-svc   ClusterIP   10.111.131.19   <none>        8080/TCP   14s   app=backend
```


```
$ k -n team-blue exec -it pod/frontend -- curl backend-svc:8080
Hello from backend on port 8080
```

Let's create the `CiliumNetworkPolicy` :

Doc : https://docs.cilium.io/en/stable/security/policy/language/#endpoints-based ang go to the section *Ingress/Egress Default Deny* in *L4* examples.

```yaml
# default-deny-ingress.yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: team-blue
spec:
  endpointSelector: {}
  ingress: []
```

or :

```yaml
...
spec:
  endpointSelector: {}
  ingress:
  - {}
```

Apply it:

```
kubectl apply -f default-deny-ingress.yaml
ciliumnetworkpolicy.cilium.io/deny-all-ingress created
```

---

### 🔍 Test communication

Use the frontend Pod to try to reach the backend service:

```
$ k -n team-blue exec -it pod/frontend -- curl backend-svc:8080 --max-time 2
curl: (28) Connection timed out after 2002 milliseconds
command terminated with exit code 28

```

### 📃 Explicit allow rule

If you want to later allow traffic selectively, you can add another `CiliumNetworkPolicy`.

Doc : https://docs.cilium.io/en/stable/security/policy/language/#layer-4-examples and serach the *Labels-dependent Layer 4 rule*


```yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: team-blue
spec:
  endpointSelector:
    matchLabels:
      app : backend
  ingress:
  - fromEndpoints:
    - matchLabels:
        role: frontend
    toPorts:
    - ports:
      - port: "8080"
        protocol: TCP
```
This only allows the Pod named `frontend` to access `backend:8080`.


```
$ k apply -f allow-frontend-to-backend.yaml 
ciliumnetworkpolicy.cilium.io/allow-frontend-to-backend configured
```

- Note : If the pod frontend does not have label, we could replace :

```yaml
  - fromEndpoints:
    - matchLabels:
        role: frontend
```

By :

```yaml
    - fromEndpoints:
      - matchLabels:
          k8s:io.kubernetes.pod.name: frontend
```

### 🔍 Test communication

```
$ k -n team-blue exec -it pod/frontend -- curl backend-svc:8080 --max-time 2
Hello from backend on port 8080
```

---

### 📖 References
- [Cilium Network Policy Docs](https://docs.cilium.io/en/stable/policy/language/)
- [Cilium Default Deny](https://docs.cilium.io/en/stable/security/identity/)

---

### ⚠️ Notes
- Default-deny should **always** be applied before any allow rules.
- Use `kubectl -n team-blue get ciliumnetworkpolicy` to list active policies.
- Use `cilium monitor` (on Cilium node) for live packet tracing (advanced).

