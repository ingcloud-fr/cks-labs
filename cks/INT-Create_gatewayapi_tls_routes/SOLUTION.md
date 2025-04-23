# ✅ SOLUTION — CS-INT_Create_gatewayapi_tls_routes

## 🎯 Lab Objective Recap
- Expose two nginx apps via Gateway API using paths `/pay` and `/shop`
- Use HTTPS with a certificate for `www.my-web-site.org`
- Terminate TLS using a `Gateway` and `GatewayClass`
- Route traffic via `HTTPRoute`

---

## 🧩 Step-by-step Solution

### 🔹 Step 1: Generate TLS Certificate and Key
```bash
$ openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=www.my-web-site.org/O=MyOrg"
```

➡️ This will produce `tls.key` and `tls.crt`.

---

### 🔹 Step 2: Create the TLS Secret

```
$ kubectl create secret tls secret-tls --cert=tls.crt --key=tls.key -n team-web
secret/secret-tls created
```


### 🔹 Step 3: Get the GatewayClass

We can see the gatewayclasses called `nginx`:

```
$ kubectl get gatewayclasses
NAME    CONTROLLER                                   ACCEPTED   AGE
nginx   gateway.nginx.org/nginx-gateway-controller   True       75s
```

### 🔹 Step 4: Create the Gateway Resource

See docs : 
- https://kubernetes.io/docs/concepts/services-networking/gateway/
- https://gateway-api.sigs.k8s.io/guides/tls/ 

```yaml
# my-gateway.yaml 
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: my-gateway
  namespace: team-web
spec:
  gatewayClassName: nginx # the gatewayClass
  listeners:
  - name: https
    protocol: HTTPS
    port: 443
    hostname: www.my-web-site.org
    tls:
      mode: Terminate
      certificateRefs:
      - name: secret-tls
        kind: Secret
        group: ""
```


```
$ k apply -f my-gateway.yaml 
gateway.gateway.networking.k8s.io/my-gateway created
```

We can see :

```
$ k -n team-web get gateway
NAME         CLASS   ADDRESS   PROGRAMMED   AGE
my-gateway   nginx             True         70s


$ k -n team-web describe gateway my-gateway
Name:         my-gateway
Namespace:    team-web
Labels:       <none>
Annotations:  <none>
API Version:  gateway.networking.k8s.io/v1
Kind:         Gateway
Metadata:
  Creation Timestamp:  2025-04-16T14:15:54Z
  Generation:          1
  Resource Version:    310021
  UID:                 23c8e0d2-1496-41cb-af17-640cfdab0ec0
Spec:
  Gateway Class Name:  nginx
  Listeners:
    Allowed Routes:
      Namespaces:
        From:  Same
    Hostname:  www.my-web-site.org
    Name:      https
    Port:      443
    Protocol:  HTTPS
    Tls:
      Certificate Refs:
        Group:  
        Kind:   Secret
        Name:   secret-tls
      Mode:     Terminate
Status:
  Conditions:
    Last Transition Time:  2025-04-16T14:15:54Z
    Message:               Gateway is accepted
    Observed Generation:   1
    Reason:                Accepted
    Status:                True
    Type:                  Accepted
    Last Transition Time:  2025-04-16T14:15:54Z
    Message:               Gateway is programmed
    Observed Generation:   1
    Reason:                Programmed
    Status:                True
    Type:                  Programmed
  Listeners:
    Attached Routes:  0
    Conditions:
      Last Transition Time:  2025-04-16T14:15:54Z
      Message:               Listener is accepted
      Observed Generation:   1
      Reason:                Accepted
      Status:                True
      Type:                  Accepted
      Last Transition Time:  2025-04-16T14:15:54Z
      Message:               Listener is programmed
      Observed Generation:   1
      Reason:                Programmed
      Status:                True
      Type:                  Programmed
      Last Transition Time:  2025-04-16T14:15:54Z
      Message:               All references are resolved
      Observed Generation:   1
      Reason:                ResolvedRefs
      Status:                True
      Type:                  ResolvedRefs
      Last Transition Time:  2025-04-16T14:15:54Z
      Message:               No conflicts
      Observed Generation:   1
      Reason:                NoConflicts
      Status:                False
      Type:                  Conflicted
    Name:                    https
    Supported Kinds:
      Group:  gateway.networking.k8s.io
      Kind:   HTTPRoute
      Group:  gateway.networking.k8s.io
      Kind:   GRPCRoute
Events:       <none>
```


### 🔹 Step 5: Create the HTTPRoute Resource

Now we create the HTTP routes for `/pay` and `/shop`

Like we need a annotion `nginx.ingress.kubernetes.io/rewrite-target: /` with Ingress, we also need to rewrite the Url, for instance /pay => / on the right service.

The doc :https://gateway-api.sigs.k8s.io/guides/http-redirect-rewrite/

```yaml
# http-routes.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: pay-shop-route
  namespace: team-web
spec:
  # This route attaches to the Gateway named 'my-gateway'
  parentRefs:
    - name: my-gateway

  # Only match requests to this host
  hostnames:
    - www.my-web-site.org

  rules:
    # First rule: matches path starting with /pay
    - matches:
        - path:
            type: PathPrefix
            value: /pay
      filters:
        - type: URLRewrite
          urlRewrite:
            path:
              type: ReplacePrefixMatch   # This means we strip the matched prefix
              replacePrefixMatch: /      # Rewrite /pay → /
      backendRefs:
        - name: backend
          port: 80                       # Forward the request to backend service on port 80

    # Second rule: matches path starting with /shop
    - matches:
        - path:
            type: PathPrefix
            value: /shop
      filters:
        - type: URLRewrite
          urlRewrite:
            path:
              type: ReplacePrefixMatch   # This means we strip the matched prefix
              replacePrefixMatch: /      # Rewrite /shop → /
      backendRefs:
        - name: frontend
          port: 80                       # Forward the request to frontend service on port 80
```




```
$ k apply -f http-routes.yaml 
httproute.gateway.networking.k8s.io/pay-shop-route created
```

### 🔍 How to Test

1. Get node IP and TLS NodePort (example: 32495):

First we get the port :

```
$ kubectl get svc -n nginx-gateway
NAME                       TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
ngf-nginx-gateway-fabric   NodePort   10.107.134.219   <none>        80:30601/TCP,443:31093/TCP   22m
```

We will use port `31093` for HTTPS.

Now the IP :

```
$ kubectl get nodes -o wide
NAME               STATUS   ROLES           AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION       CONTAINER-RUNTIME
k8s-controlplane   Ready    control-plane   47h   v1.32.3   192.168.1.200   <none>        Ubuntu 22.04.5 LTS   5.15.0-136-generic   containerd://1.7.24
k8s-node01         Ready    <none>          46h   v1.32.3   192.168.1.201   <none>        Ubuntu 22.04.5 LTS   5.15.0-136-generic   containerd://1.7.24
```



2. We can test with:

```
curl -k --resolve www.my-web-site.org:<PORT>:<NODE_IP> https://www.my-web-site.org:<PORT>/pay
```

So :

```
$ curl -k --resolve www.my-web-site.org:31095:192.168.1.200 https://www.my-web-site.org:31093/pay
<html><body><h1>Backend Page</h1></body></html>

$ curl -k --resolve www.my-web-site.org:31095:192.168.1.200 https://www.my-web-site.org:31093/shop
<html><body><h1>Frontend Page</h1></body></html>

$ curl -k --resolve www.my-web-site.org:31095:192.168.1.201 https://www.my-web-site.org:31093/pay
<html><body><h1>Backend Page</h1></body></html>

$ curl -k --resolve www.my-web-site.org:31095:192.168.1.201 https://www.my-web-site.org:31093/shop
<html><body><h1>Frontend Page</h1></body></html>
```

Or with `192.168.1.200 www.my-web-site.org` in /etc/hosts :

```
$ curl -k  https://www.my-web-site.org:31093/shop
<html><body><h1>Frontend Page</h1></body></html>

$ curl -k  https://www.my-web-site.org:31093/pay
<html><body><h1>Backend Page</h1></body></html>

```

✅ We see two different nginx pages !!

---

## ✅ Production Tips
- Use `cert-manager` with real DNS + ACME instead of OpenSSL
- Gateway API allows flexible routing for HTTP, gRPC, TCP, etc.
- Gateway and HTTPRoute are namespace-scoped and composable
- Avoid using deprecated Ingress in new projects when Gateway API is available

---

✅ Lab complete. Gateway API used successfully with TLS routing 🎉
