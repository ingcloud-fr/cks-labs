## Solution: Isolate All Egress Except DNS

### 🧠 Objective Recap
Only allow DNS resolution (UDP/TCP on port 53) to kube-dns, and block all other egress traffic from pods in the `team-dns` namespace.

---

### 🔐 NetworkPolicy: Allow only egress to DNS service
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-only-dns-egress
  namespace: team-white
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
```

---

### ✅ Explanation
- `podSelector: {}` targets all pods in the namespace.
- `policyTypes: [Egress]` means only egress is controlled.
- The only allowed destination is `kube-dns` in `kube-system`, UDP 53.
- All other egress is implicitly denied (default behavior).

---

### 🧪 Test your policy
Run the following from the pod:

```
$ k -n team-white exec -it pod/dns-tester -- nslookup www.google.com
Server:		10.96.0.10
Address:	10.96.0.10:53

Non-authoritative answer:
Name:	www.google.com
Address: 192.0.0.88
```

It returns a DNS answer ✅

```
$ k -n team-white exec -it pod/dns-tester -- wget -q --timeout=2 google.com
wget: download timed out
command terminated with exit code 1
```

Fail ❌
```

---

### 📚 References
- https://kubernetes.io/docs/concepts/services-networking/network-policies/
- https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/