# Solution: L4 and L7 Filtering using CiliumNetworkPolicy

## Objective Recap
You were asked to:
1. Deploy a simple web server exposing two endpoints: `/public` and `/admin`
2. Allow unrestricted access to `/public`
3. Allow access to `/admin` only for Pods with label `role=admin`


## ✅ Step-by-step Solution


```
$ k -n team-silver get all --show-labels 
NAME                           READY   STATUS    RESTARTS   AGE    LABELS
pod/admin-tester               1/1     Running   0          110s   role=admin
pod/httpbin-594fffb6fb-gglhp   1/1     Running   0          110s   app=httpbin,pod-template-hash=594fffb6fb
pod/httpbin-594fffb6fb-hst9h   1/1     Running   0          110s   app=httpbin,pod-template-hash=594fffb6fb
pod/user-tester                1/1     Running   0          110s   <none>

NAME                  TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE    LABELS
service/httpbin-svc   ClusterIP   10.99.41.208   <none>        8080/TCP   110s   <none>

NAME                      READY   UP-TO-DATE   AVAILABLE   AGE    LABELS
deployment.apps/httpbin   2/2     2            2           110s   <none>

NAME                                 DESIRED   CURRENT   READY   AGE    LABELS
replicaset.apps/httpbin-594fffb6fb   2         2         2       110s   app=httpbin,pod-template-hash=594fffb6fb
```


```
$ k -n team-silver exec -it pod/admin-tester -- curl http://httpbin-svc:8080/env --max-time 1
{
  "env": {
    "HTTPBIN_ENV_GREETINGS": "Hello from go-httpbin"
  }
}

$ k -n team-silver exec -it pod/admin-tester -- curl http://httpbin-svc:8080/ip --max-time 1
{
  "origin": "10.0.1.130:37664"
}

$ k -n team-silver exec -it pod/user-tester -- curl http://httpbin-svc:8080/env --max-time 1
{
  "env": {
    "HTTPBIN_ENV_GREETINGS": "Hello from go-httpbin"
  }
}

$ k -n team-silver exec -it pod/user-tester -- curl http://httpbin-svc:8080/ip --max-time 1
{
  "origin": "10.0.1.130:37664"
}
```

### 1. Create a Layer 7-aware CiliumNetworkPolicy

Documentation :https://docs.cilium.io/en/stable/security/policy/language/#http

L7 filtering requires using `toEndpoints` with `toPorts` rules that define the HTTP method and paths to allow.

```yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: endpoints-policy
  namespace: team-silver
spec:
  description: "Allow HTTP GET /env GET /get from pod"
  endpointSelector:
    matchLabels:
      app: httpbin
  ingress:
  - fromEndpoints:
    - matchLabels:
        role: admin
    toPorts:
    - ports:
      - port: "8080"
        protocol: TCP
      rules:
        http:
        - method: "GET"
          path: "/ip"
  - fromEndpoints:
    - {} # All 
    toPorts:
    - ports:
      - port: "8080"
        protocol: TCP
      rules:
        http:
        - method: "GET"
          path: "/env"
```

#### Tests


```
$ k -n team-silver exec -it pod/admin-tester -- curl http://httpbin-svc:8080/env --max-time 1
{
  "env": {
    "HTTPBIN_ENV_GREETINGS": "Hello from go-httpbin"
  }
}

$ k -n team-silver exec -it pod/admin-tester -- curl http://httpbin-svc:8080/ip --max-time 1
{
  "origin": "10.0.0.126:57658"
}

$ k -n team-silver exec -it pod/user-tester -- curl http://httpbin-svc:8080/env --max-time 1
{
  "env": {
    "HTTPBIN_ENV_GREETINGS": "Hello from go-httpbin"
  }
}

$ k -n team-silver exec -it pod/user-tester -- curl http://httpbin-svc:8080/ip --max-time 1
Access denied
```

###  2. Modify the CiliumNetworkPolicy for `default` namespace

Let's try with a new `user-tester` in `default` namespace :

```
$ k run user-tester --image curlimages/curl --command -- sleep 3600
pod/user-tester created

$ k exec -it pod/user-tester -- curl http://httpbin-svc.team-silver:8080/env --max-time 1
curl: (28) Resolving timed out after 1001 milliseconds
command terminated with exit code 28

$ k exec -it pod/user-tester -- curl http://httpbin-svc.team-silver:8080/ip --max-time 1
curl: (28) Resolving timed out after 1000 milliseconds
command terminated with exit code 28
```

We modify the rule to accept endpoints from the namespace `default` : 
- Documentation : https://docs.cilium.io/en/stable/security/policy/kubernetes/#k8s-namespaces

```yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: endpoints-policy
  namespace: team-silver
spec:
  description: "Allow HTTP GET /env GET /get"
  endpointSelector:
    matchLabels:
      app: httpbin
  ingress:
  - fromEndpoints:
    - matchLabels:     
        role: admin
    toPorts:
    - ports:
      - port: "8080"
        protocol: TCP
      rules:
        http:
        - method: "GET"
          path: "/ip"
  - fromEndpoints:
    - matchLabels:                                 # CHANGE
        k8s:io.kubernetes.pod.namespace: default   # HERE
    toPorts:
    - ports:
      - port: "8080"
        protocol: TCP
      rules:
        http:
        - method: "GET"
          path: "/env"
```

We apply :

```
$ k apply -f endpoints-policy.yaml 
ciliumnetworkpolicy.cilium.io/endpoints-policy configured
```

#### Tests

Let's test :

```
$ k exec -it pod/user-tester -- curl http://httpbin-svc.team-silver:8080/env --max-time 1
{
  "env": {
    "HTTPBIN_ENV_GREETINGS": "Hello from go-httpbin"
  }
}

$ k exec -it pod/user-tester -- curl http://httpbin-svc.team-silver:8080/ip --max-time 1
Access denied
```

## 📘 Important Notes

- Cilium must be configured with the HTTP L7 proxy enabled (default if installed via Helm)
- The Service must be a ClusterIP (or accessible within the cluster)
- If `toPorts.rules.http` is present, Cilium will enable L7 visibility on the selected ports

## 📚 References
- [Cilium L7 HTTP docs](https://docs.cilium.io/en/stable/policy/language/#http-rules)
- [Cilium toPorts syntax](https://docs.cilium.io/en/stable/policy/language/#ports)

