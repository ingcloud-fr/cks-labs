## 🛡️ Solution: Limit Ingress Between Pods with NetworkPolicies

In this lab, we must restrict all ingress traffic in a namespace, then allow communication from specific Pods on a specific port.

---

### 1. 🚫 Deny All Ingress Traffic Inside Namespace

Let's have a look on the current situation :

```
$ k -n team-green get all --show-labels 
NAME           READY   STATUS    RESTARTS   AGE   LABELS
pod/backend    1/1     Running   0          10m   app=backend
pod/frontend   1/1     Running   0          10m   app=frontend,role=frontend

NAME                   TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE   LABELS
service/backend-svc    ClusterIP   10.103.201.156   <none>        3000/TCP   10m   app=backend
service/frontend-svc   ClusterIP   10.108.206.32    <none>        80/TCP     10m   app=frontend,role=frontend

$ k get ns team-green --show-labels 
NAME         STATUS   AGE   LABELS
team-green   Active   18m   kubernetes.io/metadata.name=team-green
```

📌 Notice the `labels`

We can do some tests :

```
$ k -n team-green exec -it pod/frontend -- curl backend-svc:3000
Hello from backend

$ k exec -it pod/tester -- curl frontend-svc.team-green:80
WBITT Network MultiTool (with NGINX) - frontend - 10.0.1.211 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)

$ k exec -it pod/tester -- curl backend-svc.team-green:3000
Hello from backend
```

✅ We can see that each pod can communicate !


🧱  Create the `ingress-deny` policy:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ingress-deny
  namespace: team-green
spec:
  podSelector: {}
  policyTypes:
  - Ingress
```

🔐 This policy selects all Pods in `team-green` and blocks **all ingress** traffic.

We apply it :

```
$ k apply -f ingress-deny.yaml 
networkpolicy.networking.k8s.io/ingress-deny configured
```

### 2. 🔎 Verify Behavior

We can check :

```
$ k -n team-green exec -it pod/frontend -- curl backend-svc:3000 --max-time 2
curl: (28) Connection timed out after 2000 milliseconds

$ k exec -it pod/tester -- curl frontend-svc.team-green:80 --max-time 2
curl: (28) Connection timed out after 2002 milliseconds

$ k exec -it pod/tester -- curl backend-svc.team-green:3000 --max-time 2
curl: (28) Connection timed out after 2001 milliseconds
```

✅ The `ingress-deny` rule blocks all ingress traffic, it's just fine !


### 3. 🎯 Allow Ingress from Frontend on Port 3000

Create the `metadata-allow` policy:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ingress-allow-backend
  namespace: team-green
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: frontend
    ports:
    - protocol: TCP
      port: 3000
```
> This allows only Pods with label `role: frontend` to access the `backend` Pod **on port 3000**.

We apply 

```
$ k apply -f ingress-allow.yaml 
networkpolicy.networking.k8s.io/ingress-allow-backend configured
```

### 4. 🧪 Re-verify Behavior

```
$ k -n team-green exec -it pod/frontend -- curl backend-svc:3000 --max-time 2
Hello from backend
```

Let's try with a pod with label `role=frontend` in the `default` namespace :

```
$ k run pod-with-label --image curlimages/curl --labels "role=frontend" --command -- sleep 3600
pod/pod-with-label created

$ k exec -it pod/pod-with-label -- curl backend-svc:3000 --max-time 2
curl: (28) Resolving timed out after 2001 milliseconds
```

✅ Only ingress traffic from pod with label `role=frontend` in `team-green` namespace is allowed !

### 💡 Production Tips
- 🔐  Always start with a `default deny` NetworkPolicy in any namespace.
- 🎯  Gradually allow traffic only where justified.
- 🏷️ Document labels clearly: they are critical for policy targeting.

---

### 📚 References
- https://kubernetes.io/docs/concepts/services-networking/network-policies/

