# 🔑 SOLUTION.md - Restrict access to products-service Pod

## 🔹 Problem Understanding
We need to create a NetworkPolicy that **restricts ingress** access to a Pod `products-service` running in namespace `development`.

Allowed traffic must come from:
- Pods in namespace `team-qa` (any Pod)
- Pods in any namespace having the label `environment: staging`

All other traffic must be denied by default.

## What we have

```
$ k -n development get all --show-labels 
NAME               READY   STATUS    RESTARTS   AGE     LABELS
pod/products-pod   1/1     Running   0          3m56s   app=products

NAME                       TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE     LABELS
service/products-service   ClusterIP   10.105.36.202   <none>        80/TCP    3m56s   <none>

$ k get ns team-qa --show-labels 
NAME      STATUS   AGE     LABELS
team-qa   Active   5m16s   kubernetes.io/metadata.name=team-qa
```


## 🔹 Steps to Solve

### 1. Create the NetworkPolicy


Search for ****network policy** in documentation.

Here is a complete example of the `NetworkPolicy`:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: test-network-policy
  namespace: development
spec:
  podSelector:
    matchLabels:
      app: products
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: team-qa
    - namespaceSelector: {}
      podSelector:
        matchLabels:
          env: staging
```

Note: 

- We need to filter on the `env: staging` pod label of any namespace.
- We must therefore associate a `namespaceSelector: {}` (empty) + a `podSelector` (label matching).
👉 Otherwise, the podSelector alone will only match in `development`! Not in `team-qa`, or anywhere else.


**Important notes**:
- `podSelector` targets the **products-service Pod** (with label `app: products`).
- `policyTypes: [Ingress]` to specify we are restricting incoming traffic.
- The `from:` section includes two rules:
  - First, allow all Pods from namespace `team-qa`.
  - Second, allow any Pod with label `env: staging` in any namespace.


### 2. Apply the NetworkPolicy

Save the above manifest into a file (e.g., `networkpolicy.yaml`) and apply it:

```
$ kubectl apply -f networkpolicy.yaml
networkpolicy.networking.k8s.io/test-network-policy created
```

## 🔹 Testing the Solution

### a. Test access from allowed Pods


We launch a pod for test inside the namespace `team-qa` and test the service :


```
$ k run pod-qa -n team-qa --image curlimages/curl --restart Never --command -- sleep 3600
pod/pod-qa created


$ k -n team-qa exec -it pod/pod-qa -- curl products-service.development:80 --max-time 2 
Hello from products-pod on port 80
```

We launch a pod for test inside the namespace `default` with the label `env=staging` and test the service :

```
$ k run pod-with-label --image curlimages/curl --labels env=staging  --restart Never --command -- sleep 3600

$ k exec pod/pod-with-label -it -- curl products-service.development:80 --max-time 2
Hello from products-pod on port 80
```

### b. Test access from denied Pods
- Create a Pod without the label `env: staging` in another namespace.
- It should **fail** to connect (timeout or connection refused).


We launch a pod without no label in the default namespace :

```
$ k run pod-no-label --image curlimages/curl --restart Never --command -- sleep 3600

$ k exec pod/pod-no-label -it -- curl products-service.development:80 --max-time 2
curl: (28) Connection timed out after 2012 milliseconds
command terminated with exit code 28

```

## 🔹 Tips & Best Practices

- ✅ Always combine `podSelector` and `namespaceSelector` wisely. You can also combine both together in a single `from` rule if needed.
- ✅ Make sure default deny is activated by specifying ingress policies.
- ✅ For production, it is better to test NetworkPolicies with tools like [netshoot](https://github.com/nicolaka/netshoot) Pod.

---

## 🔹 References

- 👉 [Kubernetes Official Doc - NetworkPolicies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- 👉 [NetworkPolicy Examples](https://kubernetes.io/docs/concepts/services-networking/network-policies/#example)

---

👍 Well done! This type of exercise is very common in CKS exams!