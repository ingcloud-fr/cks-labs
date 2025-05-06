# 🌟 SOLUTION.md - Combine Ingress and Egress with CiliumNetworkPolicy

---

## Problem

The goal was to apply a single CiliumNetworkPolicy that:
- Restricts **Ingress** traffic to the `server` Pod
- Restricts **Egress** traffic from the `frontend` and `backup` Pods
- Ensures access control is enforced based on **TCP ports** and **Pod labels**

---

## ✅ Expected Policy Behavior

| From Pod | To Pod/Port | Result |
|:---------|:------------|:-------|
| `frontend` | `server:8080` | ✅ Allowed |
| `frontend` | `server:3306` | ❌ Denied |
| `backup`   | `server:3306` | ✅ Allowed |
| `backup`   | `server:8080` | ❌ Denied |

---

## ✅ First CiliumNetworkPolicy (ingress)


We have in the `team-app` namespace :

```
$ k -n team-app get all --show-labels 
NAME           READY   STATUS    RESTARTS   AGE     LABELS
pod/backup     1/1     Running   0          3m59s   role=backup
pod/frontend   1/1     Running   0          3m59s   role=frontend
pod/server     1/1     Running   0          3m20s   role=server

NAME                     TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)             AGE    LABELS
service/server-service   ClusterIP   10.106.86.175   <none>        8080/TCP,3306/TCP   106s   <none>
```

We can test :

```
$ k -n team-app exec -it pod/frontend -- curl -k https://server-service:8080
WBITT Network MultiTool (with NGINX) - server - 10.0.1.55 - HTTP: 3306 , HTTPS: 8080 . (Formerly praqma/network-multitool)

$ k -n team-app exec -it pod/frontend -- curl http://server-service:3306
WBITT Network MultiTool (with NGINX) - server - 10.0.1.55 - HTTP: 3306 , HTTPS: 8080 . (Formerly praqma/network-multitool)

$ k -n team-app exec -it pod/backup -- curl -k https://server-service:8080
WBITT Network MultiTool (with NGINX) - server - 10.0.1.55 - HTTP: 3306 , HTTPS: 8080 . (Formerly praqma/network-multitool)

$ k -n team-app exec -it pod/backup -- curl http://server-service:3306
WBITT Network MultiTool (with NGINX) - server - 10.0.1.55 - HTTP: 3306 , HTTPS: 8080 . (Formerly praqma/network-multitool)

```

Now, let's create the firt rule `restrict-l4-ingress`.


```yaml
# restrict-l4-ingress.yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: restrict-l4-ingress
  namespace: team-app
spec:
  endpointSelector:
    matchLabels:
      role: server
  ingress:
  - fromEndpoints:
    - matchLabels:
        role: frontend
    toPorts:
    - ports:
      - port: "8080"
        protocol: TCP
  - fromEndpoints:
    - matchLabels:
        role: backup
    toPorts:
    - ports:
      - port: "3306"
        protocol: TCP

```

And we apply it :

```
$ k apply -f restrict-l4-ingress.yaml
```

We can see :

```
$ k get cnp -n team-app 
NAME                  AGE   VALID
restrict-l4-ingress   21m   True

$ k describe cnp -n team-app 
Name:         restrict-l4-ingress
Namespace:    team-app
Labels:       <none>
Annotations:  <none>
API Version:  cilium.io/v2
Kind:         CiliumNetworkPolicy
Metadata:
  Creation Timestamp:  2025-04-29T09:18:35Z
  Generation:          1
  Resource Version:    1338613
  UID:                 4061ede2-391b-45c8-858b-6eea6c6f8f20
Spec:
  Endpoint Selector:
    Match Labels:
      Role:  server
  Ingress:
    From Endpoints:
      Match Labels:
        Role:  frontend
    To Ports:
      Ports:
        Port:      8080
        Protocol:  TCP
    From Endpoints:
      Match Labels:
        Role:  backup
    To Ports:
      Ports:
        Port:      3306
        Protocol:  TCP
Status:
  Conditions:
    Last Transition Time:  2025-04-29T09:18:35Z
    Message:               Policy validation succeeded
    Status:                True
    Type:                  Valid
Events:                    <none>

```

## 🔍 Tests to run from frontend

```
$ k -n team-app exec -it pod/frontend -- curl -k https://server-service:8080 --max-time 2
✅ WBITT Network MultiTool (with NGINX) - server - 10.0.1.55 - HTTP: 3306 , HTTPS: 8080 . (Formerly praqma/network-multitool)

$ k -n team-app exec -it pod/frontend -- curl http://server-service:3306 --max-time 2
❌ curl: (28) Connection timed out after 2001 milliseconds

$ k -n team-app exec -it pod/backup -- curl http://server-service:3306 --max-time 2
✅ WBITT Network MultiTool (with NGINX) - server - 10.0.1.55 - HTTP: 3306 , HTTPS: 8080 . (Formerly praqma/network-multitool)

$ k -n team-app exec -it pod/backup -- curl -k https://server-service:8080 --max-time 2
❌ curl: (28) Connection timed out after 2000 milliseconds
```

## ✅ Second CiliumNetworkPolicy (egress)

Before applying the rule, we can see on backup :

```
$ k -n team-app exec -it pod/backup -- curl http://server-service:3306 --max-time 2
WBITT Network MultiTool (with NGINX) - server - 10.0.1.55 - HTTP: 3306 , HTTPS: 8080 . (Formerly praqma/network-multitool)

$ k -n team-app exec -it pod/backup -- nslookup httpbin.org
Server:		10.96.0.10
Address:	10.96.0.10#53

Non-authoritative answer:
Name:	httpbin.org
Address: 18.209.252.14
...

$ k -n team-app exec -it pod/backup -- curl httpbin.org
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>httpbin.org</title>
...
```

```yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: restrict-l4-egress
  namespace: team-app
spec:
  endpointSelector:
    matchLabels:
      role: backup
  egress:
  - toEndpoints:
    - matchLabels:
        role: server
    toPorts:
    - ports:
      - port: "3306"
        protocol: TCP
```

```
$ k apply -f restrict-l4-egress.yaml 
ciliumnetworkpolicy.cilium.io/restrict-l4-egress created
```

But, it does not work :

```
$ k -n team-app exec -it pod/backup -- sh
/ # curl http://server-service:3306 --max-time 2
curl: (28) Resolving timed out after 2000 milliseconds
```

It's a resolver issue, we need to allow egress for DNS requests, so we modify the rule.

We have :

```
$ k -n kube-system get pod --show-labels 
NAME                                         READY   STATUS    RESTARTS       AGE     LABELS
...
coredns-668d6bf9bc-gjf2l                     1/1     Running   1 (19h ago)    5d20h   k8s-app=kube-dns,pod-template-hash=668d6bf9bc
coredns-668d6bf9bc-ql4kh                     1/1     Running   1 (19h ago)    5d20h   k8s-app=kube-dns,pod-template-hash=668d6bf9bc
...
```

The updated rule :

```yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: restrict-l4-egress
  namespace: team-app
spec:
  endpointSelector:
    matchLabels:
      role: backup
  egress:
  - toEndpoints:
    - matchLabels:
        role: server
    toPorts:
    - ports:
      - port: "3306"
        protocol: TCP
  - toEndpoints:
    - matchLabels:
        k8s:io.kubernetes.pod.namespace: kube-system
        k8s-app: kube-dns
    toPorts:
    - ports:
      - port: '53'
        protocol: UDP
      - port: '53'
        protocol: TCP

```

Note : In CiliumNetworkPolicy, there is no native `namespaceSelector` field like in standard Kubernetes NetworkPolicies. Instead, Cilium applies a special label to all Pods: `k8s:io.kubernetes.pod.namespace`, which indicates the namespace they belong to. You can use this label inside `fromEndpoints` or `toEndpoints` to effectively filter traffic based on namespaces. For example, to allow traffic only from the `kube-system` namespace, you would use matchLabels: { k8s:io.kubernetes.pod.namespace: kube-system }. This mechanism offers more flexibility and allows combining namespace and pod-level filtering in a single match.

Doc : https://docs.cilium.io/en/stable/security/policy/kubernetes/#k8s-namespaces

Let tray again the tests :

```
$ k -n team-app exec -it pod/backup -- sh

/ # curl http://server-service:3306 --max-time 2
WBITT Network MultiTool (with NGINX) - server - 10.0.1.55 - HTTP: 3306 , HTTPS: 8080 . (Formerly praqma/network-multitool)

/ # nslookup httpbin.org
Server:		10.96.0.10
Address:	10.96.0.10#53

Non-authoritative answer:
Name:	httpbin.org
...

/ # curl httpbin.org --max-time 2
curl: (28) Connection timed out after 2000 milliseconds
/ # 
```

✅ It's just fine !


## 🧠 Key Concepts

- **`fromEndpoints`** and **`toEndpoints`** use Pod labels to define traffic sources and destinations
- **`toPorts`** restrict traffic to specific TCP/UDP ports
- **CiliumNetworkPolicies** allow fine-grained control on both Ingress and Egress
- Even if a Service exists, the policy is evaluated on traffic **to the Pod IPs**, not to the Service

---

## 🛡️ Best Practices

- Always **label your Pods** clearly for use in policies (`role=frontend`, `role=backend`, etc.)
- Prefer **`toPorts`** to lock down ports explicitly
- Combine Ingress and Egress in the same policy only if logical (keep clarity)
- Always test policies from within Pods using tools like `curl`, `nc`, or `wget`

---

## 📚 Documentation links

- [Cilium Network Policies Reference](https://docs.cilium.io/en/stable/policy/language/)
- [Cilium toPorts and L4 Rules](https://docs.cilium.io/en/stable/policy/language/#ports)

---

# 🎉 Congrats! You've built and tested a real L4-level security policy using Cilium!

