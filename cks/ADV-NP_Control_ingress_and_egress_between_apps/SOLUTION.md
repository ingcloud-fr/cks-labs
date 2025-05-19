## Solution: Control Ingress and Egress Between Applications

### 🧠 Objective Recap
Enforce strict communication rules:
- Only `frontend` can access `backend`
- `backend` cannot initiate any connection
- `frontend` is not allowed to access anything except `backend`

---

### 🔐 NetworkPolicy 1 — backend-policy

We have ::

```
$  k -n team-green get all --show-labels 
NAME           READY   STATUS    RESTARTS   AGE   LABELS
pod/backend    1/1     Running   0          10s   app=backend
pod/frontend   1/1     Running   0          10s   app=frontend,role=frontend

NAME                         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE   LABELS
service/backend-svc-data     ClusterIP   10.98.122.172    <none>        3000/TCP   10s   app=backend
service/backend-svc-web      ClusterIP   10.102.244.220   <none>        80/TCP     10s   app=backend
service/frontend-svc-http    ClusterIP   10.97.11.59      <none>        80/TCP     10s   app=frontend,role=frontend
service/frontend-svc-https   ClusterIP   10.104.157.243   <none>        443/TCP    10s   app=frontend,role=frontend
```

Let's do some tests :


```
$ k -n team-green exec -it pod/backend -- curl http://frontend-svc-http
WBITT Network MultiTool (with NGINX) - frontend - 10.0.1.12 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)

$ k -n team-green exec -it pod/frontend -- curl -k https://backend-svc-data:3000
WBITT Network MultiTool (with NGINX) - backend - 10.0.1.135 - HTTP: 80 , HTTPS: 3000 . (Formerly praqma/network-multitool)

$ k -n team-green exec -it pod/frontend -- curl http://backend-svc-web
WBITT Network MultiTool (with NGINX) - backend - 10.0.1.135 - HTTP: 80 , HTTPS: 3000 . (Formerly praqma/network-multitool)

$ k exec -it pod/tester -- curl http://frontend-svc-http.team-green
WBITT Network MultiTool (with NGINX) - frontend - 10.0.1.12 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)

$ k exec -it pod/tester -- curl https://frontend-svc-https.team-green
WBITT Network MultiTool (with NGINX) - frontend - 10.0.1.12 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)

$ k exec -it pod/tester -- curl -k https://frontend-svc-https.team-green
WBITT Network MultiTool (with NGINX) - frontend - 10.0.1.145 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)

$ k exec -it pod/tester -- curl -k https://backend-svc-data.team-green:3000
WBITT Network MultiTool (with NGINX) - backend - 10.0.1.135 - HTTP: 80 , HTTPS: 3000 . (Formerly praqma/network-multitool)
```

Everything is open !

Let's create the rule `backend-policy` :

```yaml
# backend-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
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
      port: "3000"
```

✅ Allows only ingress traffic to `backend` from pods with label `app=frontend`.

```
$ k apply -f backend-policy.yaml 
networkpolicy.networking.k8s.io/backend-policy created
```

We test it :

```
$ k -n team-green exec -it pod/frontend -- curl -k https://backend-svc-data:3000 --max-time 2
WBITT Network MultiTool (with NGINX) - backend - 10.0.1.135 - HTTP: 80 , HTTPS: 3000 . (Formerly praqma/network-multitool)

$ k -n team-green exec -it pod/frontend -- curl http://backend-svc-data:80 --max-time 2
curl: (28) Connection timed out after 2001 milliseconds

$ k exec -it pod/tester -- curl -k https://backend-svc-data.team-green:3000 --max-time 2
curl: (28) Connection timed out after 2003 milliseconds
```

✅ Everything is ok ! The rule allows on Ingress traffic to backend from `role=frontend` in `team-green` nemaspace !


### 🔐 NetworkPolicy 2 — frontend-policy
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-policy
  namespace: team-green
spec:
  podSelector:
    matchLabels:
      role: frontend
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: "3000"
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
    ports:
    - protocol: UDP
      port: "53"
    - protocol: TCP
      port: "53"
```

or :

```yaml
...
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
    ports:
    - protocol: ANY
      port: "53"
```


Let's test this new rule :

```
$ k -n team-green exec -it pod/frontend -- curl -k https://backend-svc-data:3000 --max-time 2
WBITT Network MultiTool (with NGINX) - backend - 10.0.1.135 - HTTP: 80 , HTTPS: 3000 . (Formerly praqma/network-multitool)

$ k -n team-green exec -it pod/frontend -- nslookup www.google.com
Server:		10.96.0.10
Address:	10.96.0.10#53

Non-authoritative answer:
Name:	www.google.com
Address: 172.217.19.132
Name:	www.google.com
Address: 2a00:1450:4006:80e::2004

$ k -n team-green exec -it pod/frontend -- curl -k https://www.google.com --max-time 2
curl: (28) Connection timed out after 2000 milliseconds
```

✅ Everything is ok !


### 📚 References
- [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [NetworkPolicy API Reference](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.27/#networkpolicy-v1-networking-k8s-io)