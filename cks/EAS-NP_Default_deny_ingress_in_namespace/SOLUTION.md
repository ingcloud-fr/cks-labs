## Solution: Default-Deny Ingress Policy in Namespace

### 🎯 Goal
Deny all Ingress traffic in the `production` namespace by creating a default-deny `NetworkPolicy` that applies to all pods.

---

### ✅ NetworkPolicy YAML

Let's check what we have in the namespace `production` :

```
$ k -n production get all
NAME        READY   STATUS    RESTARTS   AGE
pod/nginx   1/1     Running   0          11s

NAME                TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/web-nginx   ClusterIP   10.109.45.149   <none>        80/TCP    11s

```

We launch a pod test in namespace production:

```
$ k run pod-curl -n production --image curlimages/curl --command -- sleep 3600
```

And we exec a curl to the service `web-nginx` :

```
$ k -n production exec -it pod/pod-curl -- sh
~ $ curl web-nginx:80
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
```

We launch a pod test in namespace default :

```
$ k run pod-curl-out --image curlimages/curl --command -- sleep 3600
```

And we exec a curl to the service `web-nginx` :

```
$ k exec -it  pod/pod-curl-out -- sh
~ $  curl web-nginx.production:80
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>

...
```

Ok !

Now, we have to create the deny all Network Policy.

in the documentation search for **network policy** :
- https://kubernetes.io/docs/concepts/services-networking/network-policies/#default-deny-all-ingress-traffic

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: defaultdeny
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
```

---

### 🧠 Explanation
- `podSelector: {}` applies the policy to **all pods** in the namespace
- `policyTypes: [Ingress]` declares that **Ingress traffic** is being controlled
- The absence of any `ingress` rules means **deny all** by default (implicit deny)

---

### 🧪 Test the Policy

We try accessing the nginx pod from inside again (we had --max-time option to curl) :

```
$ k exec -n production -it pod/pod-curl -- curl --max-time 2 web-nginx:80
curl: (28) Connection timed out after 2002 milliseconds
command terminated with exit code 28
```

❌ We get a timeout !

And from outside (default ns)

```
$ k exec -it  pod/pod-curl-out -- curl --max-time 2 web-nginx.production:80
curl: (28) Connection timed out after 2001 milliseconds
command terminated with exit code 28
```
So the Network Policy is ok !

---

### 📚 References
- https://kubernetes.io/docs/concepts/services-networking/network-policies/#default-deny-all-ingress-traffic