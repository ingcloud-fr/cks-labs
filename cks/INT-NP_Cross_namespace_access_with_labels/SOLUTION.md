## Solution: Cross-Namespace Access with Labels

### 🧠 Objective Recap
Allow ingress to a pod in `team-a` **only from pods in any namespace** that have the label `access=cross-team`.

---




### 🔐 NetworkPolicy: Allow ingress based on pod label only


```
$ k get all -n team-orange --show-labels 
NAME      READY   STATUS    RESTARTS   AGE   LABELS
pod/api   1/1     Running   0          81s   app=api

NAME          TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE   LABELS
service/api   ClusterIP   10.102.74.5   <none>        80/TCP    81s   <none>

$ k get all -n team-blue --show-labels 
NAME                        READY   STATUS    RESTARTS   AGE   LABELS
pod/client-with-access      1/1     Running   0          88s   access=cross-team,app=api
pod/client-without-access   1/1     Running   0          88s   app=api
```

Let's try some tests :

```
$ k -n team-blue exec -it pod/client-with-access -- curl api.team-orange:80
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...

$ k -n team-blue exec -it pod/client-without-access -- curl api.team-orange:80
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
```
















```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-cross-label
  namespace: team-a
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector: {}
      podSelector:
        matchLabels:
          access: cross-team
```

---

### ✅ Explanation
- Applies to the `api` pod in `team-a` (via `podSelector`)
- Allows traffic from **any namespace** (`namespaceSelector: {}`)
- But only if the source pod has `access: cross-team`
- All other traffic is denied (default deny)

---

### 🧪 Test Commands

```
$ k -n team-blue exec -it pod/client-with-access -- curl api.team-orange:80 --max-time 2
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...

$ k -n team-blue exec -it pod/client-without-access -- curl api.team-orange:80 --max-time 2
curl: (28) Connection timed out after 2002 milliseconds
```


### 📚 References
- [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Cross-Namespace Access with Label Filters](https://kubernetes.io/docs/concepts/services-networking/network-policies/#namespace-and-pod-selector)

