# 🌐 Create a CiliumNetworkPolicy with Combined MatchLabels for Ingress

---

## 🔢 CiliumNetworkPolicy using matchLabels (allow-ingress-strict.yaml)

```yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: "allow-ingress-strict"
  namespace: team-app
spec:
  endpointSelector:
    matchLabels:
      app: api
  ingress:
  - fromEndpoints:
    - matchLabels:
        k8s:io.kubernetes.pod.namespace: production
        policy: strict
    - matchLabels:
        k8s:io.kubernetes.pod.namespace: staging
        policy: strict
    toPorts:
    - ports:
      - port: "80"
        protocol: TCP
```

```
$ k apply -f allow-ingress-strict.yaml 
ciliumnetworkpolicy.cilium.io/allow-ingress-strict created
```

Let's do some tests :

```
$ k -n production exec -it pod/strict-client -- curl http://api-service.team-app --max-time 1
WBITT Network MultiTool (with NGINX) - api-server - 10.0.1.13 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)

$ k -n production exec -it pod/open-client -- curl http://api-service.team-app --max-time 1
curl: (28) Connection timed out after 1001 milliseconds
command terminated with exit code 28
```
```
$ k -n staging exec -it pod/strict-client -- curl http://api-service.team-app --max-time 1
WBITT Network MultiTool (with NGINX) - api-server - 10.0.1.13 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)

$ k -n staging exec -it pod/open-client -- curl http://api-service.team-app --max-time 1
curl: (28) Connection timed out after 1001 milliseconds
command terminated with exit code 28
```



### 🔍 Solution Explanation

- **endpointSelector**: targets the `api-server` Pod by selecting Pods with `app=api` label in `team-app` namespace.
- **ingress**:
  - Allows traffic **only** from Pods that:
    - Belong to the `production` namespace AND have label `policy=strict`,
    - OR belong to the `staging` namespace AND have label `policy=strict`.
  - Restricts traffic **only** to TCP port 80 (HTTP).


## 🔢 CiliumNetworkPolicy using matchExpression & matchLabels (allow-ingress-strict.yaml)

We can also use matchExpression :

```yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: allow-ingress-strict
  namespace: team-app
spec:
  endpointSelector:
    matchLabels:
      app: api
  ingress:
  - fromEndpoints:
    - matchExpressions:
      - key: "k8s:io.kubernetes.pod.namespace"
        operator: In
        values:
        - "production"
        - "staging"
      matchLabels:
        policy: strict
    toPorts:
    - ports:
      - port: "80"
        protocol: TCP
```
