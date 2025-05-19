# ✅ SOLUTION — CS-INT_Create_ingress_tls_for_apps

## 🎯 Objective Recap
The goal is to configure an Ingress with TLS to expose two nginx apps on different paths:
- `/pay`
- `/shop`

It should be accessible via the domain: `www.my-web-site.org`.

---

## 🧩 Step-by-step Solution

### 🔹 Step 1: Generate TLS Certificate and Key with OpenSSL
```bash
$ openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=www.my-web-site.org/O=MyOrg"
```

➡️ This creates:
- `tls.crt`: self-signed certificate
- `tls.key`: private key

---

### 🔹 Step 2: Create the Kubernetes TLS Secret

```
$ k -n team-web create secret tls secret-tls --cert tls.crt --key tls.key 
secret/secret-tls created
```

We can see :

```
$ k -n team-web get secrets 
NAME         TYPE                DATA   AGE
secret-tls   kubernetes.io/tls   2      25s

```

### 🔹 Step 3: Create the Ingress with TLS and Path Rules
- Use annotations for the ingress class (example: `nginx.ingress.kubernetes.io/rewrite-target: /`)
- Mount the secret as `tls.secretName`

Let's have a look at the services created :

```
$ k get svc -n team-web 
NAME       TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
backend    ClusterIP   10.104.71.195   <none>        80/TCP    6m10s
frontend   ClusterIP   10.111.67.237   <none>        80/TCP    6m10s
```

Let's have a look on the Ingress Class to get its name :

```
$ k get ingressclasses.networking.k8s.io 
NAME    CONTROLLER             PARAMETERS   AGE
nginx   k8s.io/ingress-nginx   <none>       14m
```

For the *rewrite* annotation, search in the doc for "ingress" : https://kubernetes.io/docs/concepts/services-networking/ingress/

You will find : `nginx.ingress.kubernetes.io/rewrite-target: /`

We can use the help to create a ingress :

```
$ k create ingress --help
Create an ingress with the specified name.

Aliases:
ingress, ing

Examples:
  # Create a single ingress called 'simple' that directs requests to foo.com/bar to svc
  # svc1:8080 with a TLS secret "my-cert"
  kubectl create ingress simple --rule="foo.com/bar=svc1:8080,tls=my-cert"
  
  # Create a catch all ingress of "/path" pointing to service svc:port and Ingress Class as "otheringress"
  kubectl create ingress catch-all --class=otheringress --rule="/path=svc:port"
  
  # Create an ingress with two annotations: ingress.annotation1 and ingress.annotations2
  kubectl create ingress annotated --class=default --rule="foo.com/bar=svc:port" \
  --annotation ingress.annotation1=foo \
  --annotation ingress.annotation2=bla
...
```

Ok, now we have everything to create the ingress, just try in *dry-run* mode  :

```
$ k -n team-web create ingress my-ingress-tls \
   --rule="www.my-web-site.org/shop*=frontend:80,tls=secret-tls" \
   --rule="www.my-web-site.org/pay*=backend:80,tls=secret-tls"  \
   --annotation nginx.ingress.kubernetes.io/rewrite-target=/  \
   --class nginx \
   -o yaml --dry-run=client
```

We get :

``` yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
  creationTimestamp: null
  name: my-ingress-tls
  namespace: team-web
spec:
  ingressClassName: nginx
  rules:
  - host: www.my-web-site.org
    http:
      paths:
      - backend:
          service:
            name: frontend
            port:
              number: 80
        path: /shop
        pathType: Prefix
      - backend:
          service:
            name: backend
            port:
              number: 80
        path: /pay
        pathType: Prefix
  tls:
  - hosts:
    - www.my-web-site.org
    secretName: secret-tls
status:
  loadBalancer: {}
```

It's ok, now we can run the command :

```
$ k -n team-web create ingress my-ingress-tls \
   --rule="www.my-web-site.org/shop*=frontend:80,tls=secret-tls" \
   --rule="www.my-web-site.org/pay*=backend:80,tls=secret-tls"  \
   --annotation nginx.ingress.kubernetes.io/rewrite-target=/  \
   --class nginx
ingress.networking.k8s.io/my-ingress-tls created
```

Notes :
- we use `*` in *rules* for **Prefix** mode

We can see :

```
$ k -n team-web describe ingress
Name:             my-ingress-tls
Labels:           <none>
Namespace:        team-web
Address:          10.98.156.244
Ingress Class:    nginx
Default backend:  <default>
TLS:
  secret-tls terminates www.my-web-site.org
Rules:
  Host                 Path  Backends
  ----                 ----  --------
  www.my-web-site.org  
                       /shop   frontend:80 (10.0.1.14:80)
                       /pay    backend:80 (10.0.1.177:80)
Annotations:           nginx.ingress.kubernetes.io/rewrite-target: /
Events:
  Type    Reason  Age                From                      Message
  ----    ------  ----               ----                      -------
  Normal  Sync    16s (x2 over 31s)  nginx-ingress-controller  Scheduled for sync
```

## 🧪 How to Test

We can see the Ingress Controller :

```
$ kubectl get svc ingress-nginx-controller -n ingress-nginx
NAME                       TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
ingress-nginx-controller   NodePort   10.98.156.244   <none>        80:31668/TCP,443:32495/TCP   12m
```

This IP (`10.98.156.244`) corresponds to the *internal ClusterIP address* of the `ingress-nginx-controller` service.

But it's not directly accessible from the host (since it's an internal cluster IP). You have to use the **NodePort** with the port `32495` for https (`443:32495/TCP`)

We get an IP address :

```
$ kubectl get nodes -o wide
NAME               STATUS   ROLES           AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION       CONTAINER-RUNTIME
k8s-controlplane   Ready    control-plane   43h   v1.32.3   192.168.1.200   <none>        Ubuntu 22.04.5 LTS   5.15.0-136-generic   containerd://1.7.24
k8s-node01         Ready    <none>          43h   v1.32.3   192.168.1.201   <none>        Ubuntu 22.04.5 LTS   5.15.0-136-generic   containerd://1.7.24
```

We can test on all the adresses using curl with `--resolve`  :

```
$ curl -k --resolve www.my-web-site.org:32495:192.168.1.200 https://www.my-web-site.org:32495/shop
<html><body><h1>Frontend Page</h1></body></html>

$ curl -k --resolve www.my-web-site.org:32495:192.168.1.201 https://www.my-web-site.org:32495/shop
<html><body><h1>Frontend Page</h1></body></html>

$ curl -k --resolve www.my-web-site.org:32495:192.168.1.200 https://www.my-web-site.org:32495/pay
<html><body><h1>Backend Page</h1></body></html>

$ curl -k --resolve www.my-web-site.org:32495:192.168.1.201 https://www.my-web-site.org:32495/pay
<html><body><h1>Backend Page</h1></body></html>
```

Or we can add the IP to /etc/hosts

```
$ echo "192.168.1.200 www.my-web-site.org" | sudo tee -a /etc/hosts
192.168.1.200 www.my-web-site.org
```

And test :

```
$ curl -k  https://www.my-web-site.org:32495/pay
<html><body><h1>Backend Page</h1></body></html>

$ curl -k  https://www.my-web-site.org:32495/shop
<html><body><h1>Frontend Page</h1></body></html>
```



## 🛡️ Good Practices
- In production, use **cert-manager** instead of manual `openssl`
- On cloud provider, you will have a LoadBalancer
- You can test locally the loadbalancer metalLb
- Now we can use the Gateway API.
- Always validate the DNS or `/etc/hosts` resolution before curl tests
- Monitor the ingress controller logs for troubleshooting

---

✅ Lab completed.
