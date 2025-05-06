## ✅ Solution: Allow DNS and ICMP EchoRequest Only

In this lab, the goal was to create a `CiliumNetworkPolicy` that:

* Blocks all default egress traffic.
* Explicitly **allows only** DNS queries (UDP 53) and ICMP EchoRequest messages (type 8 for IPv4, EchoRequest for IPv6).

---

### 1. 🧱 Default-Deny Behavior by Design

In Cilium, any traffic **not explicitly allowed** by a CNP is **denied by default**.
So if your policy only allows DNS and ICMP, then everything else (HTTP, SSH, etc.) is blocked automatically — no need for an explicit `deny`.

---

### 2. 📝 CiliumNetworkPolicy to Create

```yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: egress-allow-dns-icmp
  namespace: team-gray
spec:
  endpointSelector: {}
  egress:
  - toPorts:
      - ports:
         - port: "53"
           protocol: ANY
  - icmps:
    - fields:
      - type: 8
        family: IPv4
      - type: EchoRequest
        family: IPv6
```

### 📌 Explanation:

* `endpointSelector: {}` applies to **all Pods** in the namespace `team-gray`.
* First egress rule:
  * Allows **DNS** traffic via UDP port 53.

* Second egress rule:
  * Allows **ICMP EchoRequest** (ping) only:

    * `type: 8` for IPv4 is EchoRequest.
    * `type: EchoRequest` for IPv6 (this is supported syntax in Cilium).

---

### 3. 🔍 How to Verify

#### ✅ DNS OK

```
$ k -n team-gray exec -it pod/tester -- host www.google.com
www.google.com has address 142.250.75.228
www.google.com has IPv6 address 2a00:1450:4006:80c::2004
```

#### ✅ ICMP OK (internal node or pod IP)

```
$ k -n team-gray exec -it pod/tester -- ping www.google.com
PING www.google.com (142.250.75.228) 56(84) bytes of data.
64 bytes from par10s41-in-f4.1e100.net (142.250.75.228): icmp_seq=1 ttl=59 time=18.1 ms
64 bytes from par10s41-in-f4.1e100.net (142.250.75.228): icmp_seq=2 ttl=59 time=28.6 ms
^C
```

> If ICMP fails: Try with the IP of another Pod, or the default gateway of the node.

#### ❌ HTTP/HTTPS Should Fail

```
$ k -n team-gray exec -it pod/tester -- curl -s https://google.com --max-time 1
command terminated with exit code 28
```

---

### 🔐 Production Tips

* Always isolate egress traffic using `egress` rules.
* Use DNS + ICMP allowances with **fine-grained selectors** in production — not `endpointSelector: {}`.
* For auditing or troubleshooting, enable **Hubble** and inspect egress decisions.

---

### 📚 References

- https://docs.cilium.io/en/stable/security/policy/language/#example-icmp-icmpv6
- https://docs.cilium.io/en/stable/security/policy/language/#dns-based