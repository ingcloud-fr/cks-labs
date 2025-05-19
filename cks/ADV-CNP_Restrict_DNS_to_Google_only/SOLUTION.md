## Solution: Restrict DNS Resolution to Google Domains Only

This lab demonstrates how to apply a `CiliumNetworkPolicy` to restrict DNS queries from Pods to specific domain names (`google.com` and `google.fr`).

---

### ✅ Step-by-Step Solution

#### 1. Understand the DNS behavior in Kubernetes

* All Pods typically use a local DNS resolver (e.g. CoreDNS) to resolve names.
* Cilium can enforce DNS-level filtering via L7 DNS rules in CNPs.
* To apply DNS policies, Cilium must have `dnsProxy` enabled (it's usually enabled by default).

---

#### 2. Apply the following `CiliumNetworkPolicy`

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: "allow-google-dns-only"
  namespace: team-purple
spec:
  endpointSelector: {}
  egress:
  - toEndpoints:
    - matchLabels:
       "k8s:io.kubernetes.pod.namespace": kube-system
       "k8s:k8s-app": kube-dns
    toPorts:
      - ports:
         - port: "53"
           protocol: ANY
        rules:
          dns:
            - matchName: "google.com"
            - matchPattern: "*.google.com"
            - matchPattern: "*.*.svc.cluster.local"
```

✅ This policy allows **only DNS requests to `google.com` and `google.fr`**.

❌ All other DNS queries will be dropped by Cilium’s DNS proxy.

---

### ✅ Test the result

From the test Pod:

```
$ k -n team-purple exec -it pod/tester -- sh
```

```
$ nslookup google.com
Server:		10.96.0.10
Address:	10.96.0.10:53

Non-authoritative answer:
Name:	google.com
Address: 192.0.0.88

Non-authoritative answer:

~ $ nslookup www.google.com
Server:		10.96.0.10
Address:	10.96.0.10:53

Non-authoritative answer:

Non-authoritative answer:
Name:	www.google.com
Address: 192.0.0.88

~ $ nslookup nginx.team-green.svc.cluster.local
Server:		10.96.0.10
Address:	10.96.0.10:53


Name:	nginx.team-green.svc.cluster.local
Address: 10.106.77.64

~ $ nslookup www.bing.com
Server:		10.96.0.10
Address:	10.96.0.10:53

** server can't find www.bing.com: REFUSED

** server can't find www.bing.com: REFUSED

~ $ exit


```

Inside the Pod:

```sh
nslookup google.com         # ✅ 
nslookup www.google.com     # ✅ 
nslookup nginx.team-green.svc.cluster.local     # ✅ 
nslookup www.bing.com       # ❌ Should timeout or fail
```

### 📘 References

* [Cilium DNS Policy Docs](https://docs.cilium.io/en/stable/security/policy/language/#dns-policy-and-ip-discovery)
