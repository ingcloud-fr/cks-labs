## Solution: Allow Service by Labels with CiliumNetworkPolicy

### 🔑 Goal
Restrict access to a backend pod so that only pods with label `role=client` can communicate with it. All other ingress traffic must be denied.

---

### 🔧 Step-by-Step Solution

#### 1. Inspect existing pods

```
$ k -n team-green get all --show-labels 
NAME           READY   STATUS    RESTARTS   AGE   LABELS
pod/backend    1/1     Running   0          97s   app=backend,role=backend
pod/client     1/1     Running   0          97s   app=client,role=client
pod/intruder   1/1     Running   0          97s   <none>

NAME                  TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE   LABELS
service/backend-svc   ClusterIP   10.99.166.166   <none>        8080/TCP   5s    app=backend,role=backend
```


```
$ k -n team-green exec -it pod/client -- curl backend-svc:8080
Hello from backend on port 8080

$ k -n team-green exec -it pod/intruder -- curl backend-svc:8080
Hello from backend on port 8080
```



#### 2. Write the CiliumNetworkPolicy

Doc : https://docs.cilium.io/en/stable/security/policy/language/#endpoints-based ang go to the section *Ingress/Egress Default Deny* in *L4* examples.

Create a manifest file (e.g. `allow-client-to-backend.yaml`) with the following content:

```yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: allow-client-to-backend
  namespace: team-green
spec:
  endpointSelector:
    matchLabels:
      role: backend
  ingress:
  - fromEndpoints:
    - matchLabels:
        role: client
    toPorts:
    - ports:
      - port: "8080"
        protocol: TCP
```

---

#### 3. Apply the policy
```bash
kubectl apply -f cnp-allow-role-client.yaml
```

---

#### 4. Test connectivity

```
$ k -n team-green exec -it pod/client -- curl backend-svc:8080 --max-time 2
Hello from backend on port 8080

$ k -n team-green exec -it pod/intruder -- curl backend-svc:8080 --max-time 2
curl: (28) Connection timed out after 2002 milliseconds
command terminated with exit code 28
```

### 🔍 Validation
- Only pods with `role=client` can reach `backend`.
- Other pods are blocked at L3/L4 by the Cilium policy.

---

### 🔹 Production Tips
- Always test CNPs with temporary `toFQDNs` or `toPorts` open to validate pod communication.
- Combine `endpointSelector` with additional layers (e.g. namespace selectors) in more complex scenarios.

---

### 🔎 References
- [Cilium Network Policy - Official Docs](https://docs.cilium.io/en/stable/network/layer-3-policy/)
- [CNP Examples](https://docs.cilium.io/en/stable/policy/language/)

---

