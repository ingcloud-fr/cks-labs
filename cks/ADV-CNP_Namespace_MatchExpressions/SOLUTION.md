# 🌟 CiliumNetworkPolicy with Namespace and Label MatchExpressions




## 📖 What we have

Let's get the pods and their label :

```
$ k -n team-app get all --show-labels 
NAME             READY   STATUS    RESTARTS   AGE   LABELS
pod/api-server   1/1     Running   0          40s   app=api

NAME                  TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE   LABELS
service/api-service   ClusterIP   10.96.212.205   <none>        80/TCP    40s   <none>

$ k -n staging get pods --show-labels 
NAME                READY   STATUS    RESTARTS   AGE   LABELS
pod/open-client     1/1     Running   0          44s   policy=open
pod/strict-client   1/1     Running   0          44s   policy=strict

$ k -n production get pods --show-labels 
NAME                READY   STATUS    RESTARTS   AGE   LABELS
pod/open-client     1/1     Running   0          48s   policy=open
pod/strict-client   1/1     Running   0          48s   policy=strict

$ k -n team-app get pods --show-labels 
NAME            READY   STATUS    RESTARTS   AGE    LABELS
api-server      1/1     Running   0          50s   app=api
open-client     1/1     Running   0          50s   policy=open
strict-client   1/1     Running   0          50s   policy=strict


$ k get pods --show-labels 
NAME            READY   STATUS    RESTARTS   AGE     LABELS
open-client     1/1     Running   0          51s   policy=open
strict-client   1/1     Running   0          51s   policy=strict

```

The tests before applying the rule :

```bash
# From production
$ k -n production exec -it pod/open-client -- curl api-service.team-app:80 --max-time 2
WBITT Network MultiTool (with NGINX) - api-server - 10.0.1.112 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)

$ k -n production exec -it pod/strict-client -- curl api-service.team-app:80 --max-time 2
WBITT Network MultiTool (with NGINX) - api-server - 10.0.1.112 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)

# From staging
$ k -n staging exec -it pod/open-client -- curl api-service.team-app:80 --max-time 2
WBITT Network MultiTool (with NGINX) - api-server - 10.0.1.112 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)

$ k -n staging exec -it pod/strict-client -- curl api-service.team-app:80 --max-time 2
WBITT Network MultiTool (with NGINX) - api-server - 10.0.1.112 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)

# From team-app
$ k -n team-app exec -it pod/open-client -- curl api-service.team-app:80 --max-time 2
WBITT Network MultiTool (with NGINX) - api-server - 10.0.1.101 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)

$ k -n team-app exec -it pod/strict-client -- curl api-service.team-app:80 --max-time 2
WBITT Network MultiTool (with NGINX) - api-server - 10.0.1.101 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)

# From default
$ k exec -it pod/open-client -- curl api-service.team-app:80 --max-time 2
WBITT Network MultiTool (with NGINX) - api-server - 10.0.1.9 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)

$ k exec -it pod/strict-client -- curl api-service.team-app:80 --max-time 2
WBITT Network MultiTool (with NGINX) - api-server - 10.0.1.9 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)
```

## 📄 First rule

Create a `CiliumNetworkPolicy` named `restrict-namespaces-and-labels` that restricts **Ingress** to the `api-server` Pod.
Only allow traffic from Pods that:
- Belong to the namespace `production` **or** `staging`
- **AND** have the label `policy=strict`
Using `matchExpression`.

Let's create a rule using `matchExpressions` !

Doc: https://docs.cilium.io/en/stable/security/policy/kubernetes/#match-expressions


```yaml
# restrict-namespaces-and-labels.yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: restrict-namespaces-and-labels
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
      - key: policy
        operator: In
        values:
        - "strict"
```

We apply it :

```
$ k apply -f restrict-namespaces-and-labels.yaml 
ciliumnetworkpolicy.cilium.io/restrict-namespaces-and-labels configured
```

We can see :

```yaml
$ k -n team-app describe cnp restrict-namespaces-and-labels 
Name:         restrict-namespaces-and-labels
Namespace:    team-app
Labels:       <none>
Annotations:  <none>
API Version:  cilium.io/v2
Kind:         CiliumNetworkPolicy
Metadata:
  Creation Timestamp:  2025-04-29T23:20:03Z
  Generation:          1
  Resource Version:    1541184
  UID:                 3a927545-238e-4e2e-bce9-e1c530ad90d9
Spec:
  Endpoint Selector:
    Match Labels:
      App:  api
  Ingress:
    From Endpoints:
      Match Expressions:
        Key:       k8s:io.kubernetes.pod.namespace
        Operator:  In
        Values:
          production
          staging
        Key:       policy
        Operator:  In
        Values:
          strict
Status:
  Conditions:
    Last Transition Time:  2025-04-29T23:20:03Z
    Message:               Policy validation succeeded
    Status:                True
    Type:                  Valid
Events:                    <none>
```

We check :

```bash
# From production 
$ k -n production exec -it pod/strict-client -- curl api-service.team-app:80 --max-time 2
WBITT Network MultiTool (with NGINX) - api-server - 10.0.1.112 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)

$ k -n production exec -it pod/open-client -- curl api-service.team-app:80 --max-time 2
curl: (28) Connection timed out after 2001 milliseconds
command terminated with exit code 28

# From staging
$ k -n staging exec -it pod/strict-client -- curl api-service.team-app:80 --max-time 2
WBITT Network MultiTool (with NGINX) - api-server - 10.0.1.112 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)

$ k -n staging exec -it pod/open-client -- curl api-service.team-app:80 --max-time 2
curl: (28) Connection timed out after 2000 milliseconds
command terminated with exit code 28

# from team-app
$ k -n team-app exec -it pod/strict-client -- curl api-service.team-app:80 --max-time 2
curl: (28) Connection timed out after 2000 milliseconds
command terminated with exit code 28

$ k -n team-app exec -it pod/open-client -- curl api-service.team-app:80 --max-time 2
curl: (28) Connection timed out after 2000 milliseconds
command terminated with exit code 28

# from default
$ k exec -it pod/strict-client -- curl api-service.team-app:80 --max-time 2
curl: (28) Connection timed out after 2000 milliseconds
command terminated with exit code 28

$ k exec -it pod/open-client -- curl api-service.team-app:80 --max-time 2
curl: (28) Connection timed out after 2001 milliseconds
command terminated with exit code 28
```


| Namespace   | Pod Name       | Access to api-service.team-app:80 | Result       |
|:------------|:---------------|:----------------------------------|:-------------|
| production  | strict-client   | ✅ Success                        | HTTP 200 OK  |
| production  | open-client     | ❌ Timeout                       | Connection Timeout |
| staging     | strict-client   | ✅ Success                        | HTTP 200 OK  |
| staging     | open-client     | ❌ Timeout                       | Connection Timeout |
| team-app    | strict-client   | ❌ Timeout                       | Connection Timeout |
| team-app    | open-client     | ❌ Timeout                       | Connection Timeout |
| default     | strict-client   | ❌ Timeout                       | Connection Timeout |
| default     | open-client     | ❌ Timeout                       | Connection Timeout |


## 📄 Second rule

Modify the `CiliumNetworkPolicy` that restricts **Ingress** to the `api-server` Pod.
Only allow traffic from Pods that:
- Belong to the namespace `production` **or** `staging`
- **OR** have the label `policy=strict`
Using `matchExpression`.

```yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: restrict-namespaces-and-labels
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
    - matchExpressions:
      - key: policy
        operator: In
        values:
        - "strict"
      - key: "k8s:io.kubernetes.pod.namespace"
        operator: Exists
```

We apply it :

```
$ k apply -f restrict-namespaces-and-labels.yaml 
ciliumnetworkpolicy.cilium.io/restrict-namespaces-and-labels configured
```

We test :

```bash
# From production 
$ k -n production exec -it pod/strict-client -- curl api-service.team-app:80 --max-time 2
WBITT Network MultiTool (with NGINX) - api-server - 10.0.1.112 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)

$ k -n production exec -it pod/open-client -- curl api-service.team-app:80 --max-time 2
WBITT Network MultiTool (with NGINX) - api-server - 10.0.1.112 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)

# From staging
$ k -n staging exec -it pod/strict-client -- curl api-service.team-app:80 --max-time 2
WBITT Network MultiTool (with NGINX) - api-server - 10.0.1.112 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)

$ k -n staging exec -it pod/open-client -- curl api-service.team-app:80 --max-time 2
WBITT Network MultiTool (with NGINX) - api-server - 10.0.1.112 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)

# from team-app
$ k -n team-app exec -it pod/strict-client -- curl api-service.team-app:80 --max-time 2
WBITT Network MultiTool (with NGINX) - api-server - 10.0.1.112 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)

$ k -n team-app exec -it pod/open-client -- curl api-service.team-app:80 --max-time 2
curl: (28) Connection timed out after 2000 milliseconds
command terminated with exit code 28

# from default
$ k exec -it pod/strict-client -- curl api-service.team-app:80 --max-time 2
WBITT Network MultiTool (with NGINX) - api-server - 10.0.1.112 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)

$ k exec -it pod/open-client -- curl api-service.team-app:80 --max-time 2
curl: (28) Connection timed out after 2001 milliseconds
command terminated with exit code 28
```

| Namespace   | Pod Name       | Access to api-service.team-app:80 | Result            |
|-------------|----------------|------------------------------------|-------------------|
| production  | strict-client  | ✅ Allowed                         | HTTP 200 OK       |
| production  | open-client    | ✅ Allowed                         | HTTP 200 OK       |
| staging     | strict-client  | ✅ Allowed                         | HTTP 200 OK       |
| staging     | open-client    | ✅ Allowed                         | HTTP 200 OK       |
| team-app    | strict-client  | ✅ Allowed                         | HTTP 200 OK       |
| team-app    | open-client    | ❌ Denied                          | Timeout           |
| default     | strict-client  | ✅ Allowed                         | HTTP 200 OK       |
| default     | open-client    | ❌ Denied                          | Timeout           |



### ❌ Why a `matchExpressions` with only `policy=strict` Fails Outside the Policy Namespace

When writing a `CiliumNetworkPolicy`, one common misunderstanding is assuming that this block:

```yaml
fromEndpoints:
  - matchExpressions:
    - key: policy
      operator: In
      values:
        - "strict"
```

…will match **any** Pod with the label `policy=strict` in **any** namespace.

But in practice, it **only matches Pods in the same namespace as the CNP**, unless you explicitly add a namespace condition.

---

#### 🔍 Explanation

Cilium constructs an **identity** for each Pod based on multiple labels, including:

- Pod labels (e.g. `policy=strict`)
- Namespace (e.g. `k8s:io.kubernetes.pod.namespace=staging`)
- ServiceAccount
- Others...

When you use `matchExpressions`, Cilium will try to match **all expressions in the same block** against the full identity.

If your identity looks like this:

```
k8s:policy=strict
k8s:io.kubernetes.pod.namespace=staging
```

…then a block that only requires `policy=strict`:

```yaml
- matchExpressions:
    - key: policy
      operator: In
      values:
        - strict
```

…will **fail to match**, unless the Pod is in the **same namespace** as the CNP (where Cilium can implicitly reduce the identity scope).

---

#### ✅ Correct usage: adding `namespace Exists`

To allow Pods with `policy=strict` in any namespace, you must write:

```yaml
- matchExpressions:
    - key: policy
      operator: In
      values:
        - strict
    - key: k8s:io.kubernetes.pod.namespace
      operator: Exists
```

This tells Cilium:
> I expect the Pod to have label `policy=strict` **AND** belong to *some* namespace (which is always true).

Only then will the `fromEndpoints` match Pods from outside the namespace where the CNP is declared.

---

#### ✉ Summary

| Pattern | Scope |
|--------|-------|
| Only `policy=strict` | Matches **only** Pods in the CNP's namespace |
| `policy=strict` + `namespace Exists` | Matches Pods in **any** namespace |

Always consider the full identity (not just Pod labels) when crafting `matchExpressions` in Cilium policies.

## About namespace filtering with Cilium

Cilium, internally :

- dynamically adds a special label to each Pod `k8s:io.kubernetes.pod.namespace`
- to target namespaces even in Pod-based policies.

This is a Cilium-specific feature to make selection more flexible!

Unlike classic Network Policies, in Ciliul there is no namespaceSelector, Cilium handles things differently:

- toEndpoints/fromEndpoints use Pod labels (only).
- Not directly a namespaceSelector.

BUT, Cilium automatically injects a special label on each Pod:

k8s:io.kubernetes.pod.namespace: <namespace> The namespace to which the Pod belongs.

✅ So in practice, with Cilium, to filter on a namespace, you need to make a matchLabel on this label.

Cilium equivalent example for namespaceSelector :

```
fromEndpoints:
  - matchLabels:
      k8s:io.kubernetes.pod.namespace: kube-system
```

Important to remember with Cilium : 

- No native namespaceSelector: field in CiliumNetworkPolicy.
- We filter namespaces by targeting the special Pod label: k8s:io.kubernetes.pod.namespace.
- It's more flexible (you can easily combine several criteria).      

Doc: https://docs.cilium.io/en/stable/security/policy/kubernetes/#k8s-namespaces 

## 📅 Good Practices

- Use `matchExpressions` for **combinations** of label logic (in/notin/exists).
- Leverage Cilium's `k8s:io.kubernetes.pod.namespace` to emulate namespaceSelector.
- Always test policies from within running Pods.
- Make sure to include **DNS egress** if your pods rely on names instead of IPs.

---

## 🔗 References

- [Cilium matchExpressions syntax](https://docs.cilium.io/en/stable/policy/language/#matching-labels)
- [Cilium identity model](https://docs.cilium.io/en/stable/security/identity/)
- [CiliumNetworkPolicy examples](https://docs.cilium.io/en/stable/policy/language/#ciliumnetworkpolicy)

---

# 🎉 Great job! You've secured traffic using both namespace scope and label-based filtering with Cilium.