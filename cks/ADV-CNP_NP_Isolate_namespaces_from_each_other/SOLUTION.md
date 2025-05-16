# Solution## Solution: Isolate Team Namespaces with Network Policies

### 🧠 Objective Recap
Ensure that pods in each team namespace (`team-blue`, `team-red`) can only communicate with pods within the same namespace usin ingress.

###

We have :

```
$ k -n team-green get all

```

- Note: the same thing for the 2 other namespaces.

Let's create 1 pod to test in each namespace :

```
$ k -n team-blue run podtest --image curlimages/curl -- sleep 3600
pod/podtest created

$ k -n team-red run podtest --image curlimages/curl -- sleep 3600
pod/podtest created
```

Let's test before applying a NetworkPolicy:

```
$ k -n team-blue exec -it podtest -- curl http://nginx --max-time 1
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...

$ k -n team-blue exec -it podtest -- curl http://nginx.team-red --max-time 1
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...

$ k -n team-red exec -it podtest -- curl http://nginx --max-time 1
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...

$ k -n team-red exec -it podtest -- curl http://nginx.team-blue --max-time 1
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
```


### 🔐 NetworkPolicy: allow ingress only from same namespace

This policy is to be applied once per namespace.
You can use the exact same YAML file with a `kubectl apply -n <namespace> -f <file>`.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-same-namespace-only
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: {}
```

What it means:

* Applies to **all Pods** in the namespace (`podSelector: {}`).
* Allows **Ingress traffic only from Pods within the same namespace** (because `from.podSelector: {}` does **not specify namespace**, so it defaults to the same one).
* All other Ingress traffic (from other namespaces) is **denied**.

Apply the policy to each namespace :

```
$ k apply -f allow-same-namespace-only.yaml -n team-blue 
networkpolicy.networking.k8s.io/allow-same-namespace-only created

$ k apply -f allow-same-namespace-only.yaml -n team-red 
networkpolicy.networking.k8s.io/allow-same-namespace-only created
```

We can see :

```
$ k -n team-blue describe networkpolicies allow-same-namespace-only 
Name:         allow-same-namespace-only
Namespace:    team-blue
Created on:   2025-05-16 02:42:44 +0000 UTC
Labels:       <none>
Annotations:  <none>
Spec:
  PodSelector:     <none> (Allowing the specific traffic to all pods in this namespace)
  Allowing ingress traffic:
    To Port: <any> (traffic allowed to all ports)
    From:
      PodSelector: <none>
  Not affecting egress traffic
  Policy Types: Ingress
```

Let's test :

```
$ k -n team-blue exec -it podtest -- curl http://nginx --max-time 1
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...

$ k -n team-blue exec -it podtest -- curl http://nginx.team-red --max-time 1
curl: (28) Connection timed out after 1002 milliseconds
command terminated with exit code 28

$ k -n team-red exec -it podtest -- curl http://nginx --max-time 1
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...

$ k -n team-red exec -it podtest -- curl http://nginx.team-blue --max-time 1
curl: (28) Connection timed out after 1002 milliseconds
command terminated with exit code 28
...
```


#### ✅ **Result**:

* Traffic **from Pods in the same namespace**: ✅ allowed
* Traffic **from other namespaces**: ❌ denied

#### Common errors

This NP :

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-same-namespace-only
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress: 
    - {}
```

**What it means:**

* Applies to **all Pods**.
* The ingress rule is an **empty rule block** (`{}`), which means: "allow all Ingress traffic from any source".
* Since a `NetworkPolicy` exists, Kubernetes applies **default deny** logic to non-selected traffic **unless it's explicitly allowed** — and here, it's **all allowed**.

**Result**:

* All Ingress traffic from **any namespace, any Pod, any IP**: ✅ allowed

And this one :

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-same-namespace-only
spec:
  podSelector: {}
  policyTypes:
  - Ingress
```

**What it means:**

* Applies to **all Pods**.
* No `ingress` block is defined at all → no traffic is explicitly allowed.
* Therefore, all Ingress traffic is **denied**.

**Result**:

* All Ingress traffic: ❌ denied

### Using CiliumNetworkPolicy

We delete the rules :

```
$ k delete -f allow-same-namespace-only.yaml -n team-red
networkpolicy.networking.k8s.io "allow-same-namespace-only" deleted

$ k delete -f allow-same-namespace-only.yaml -n team-blue
networkpolicy.networking.k8s.io "allow-same-namespace-only" deleted
```

And create a NetworkPolicy :

```yaml
# cnp-allow-same-namespace-only.yaml 
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: cnp-allow-same-namespace-only
spec:
  endpointSelector: {}
  ingress:
  - fromEndpoints: 
    - {}
```

🔍 Explanation :
- Applies to all Pods in the namespace (endpointSelector: {} matches everything in the namespace).
- Allows Ingress traffic from all Pods in the same namespace (fromEndpoints: [{}] allows any source within the namespace).
- Effectively blocks all cross-namespace traffic, since no external sources or namespace labels are allowed.


```
$ k apply -f cnp-allow-same-namespace-only.yaml -n team-blue
ciliumnetworkpolicy.cilium.io/cnp-allow-same-namespace-only created

$ k apply -f cnp-allow-same-namespace-only.yaml -n team-red 
ciliumnetworkpolicy.cilium.io/cnp-allow-same-namespace-only created
```

Let's test :

```
$ k -n team-blue exec -it podtest -- curl http://nginx --max-time 1
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...

$ k -n team-blue exec -it podtest -- curl http://nginx.team-red --max-time 1
curl: (28) Connection timed out after 1002 milliseconds
command terminated with exit code 28

$ k -n team-red exec -it podtest -- curl http://nginx --max-time 1
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...

$ k -n team-red exec -it podtest -- curl http://nginx.team-blue --max-time 1
curl: (28) Connection timed out after 1002 milliseconds
command terminated with exit code 28
...
```

#### ✅ **Result**:

* Traffic **from Pods in the same namespace**: ✅ allowed
* Traffic **from other namespaces**: ❌ denied

#### Common errors

```yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: cnp-allow-same-namespace-only
spec:
  endpointSelector: {}
  ingress:
  - {}
```

What this **CiliumNetworkPolicy** *actually* does:

1. It applies to **all Pods** in the namespace (`endpointSelector: {}`).
2. The `ingress: - {}` block defines **no explicit source**.
3. **Result: all Ingress traffic is denied**, including traffic from the same namespace.

> ⚠️ Unlike standard Kubernetes `NetworkPolicy`, in Cilium a rule like `ingress: - {}` **does not mean "allow all"**. It is interpreted as "no source defined" → **deny all by default**.



### 📚 References
- [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)


