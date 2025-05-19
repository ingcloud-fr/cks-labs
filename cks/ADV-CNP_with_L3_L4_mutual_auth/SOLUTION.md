## Solution: Combine L3/L4 Rules and Mutual Authentication in Cilium

This lab aims to practice fine-grained control of network traffic using CiliumNetworkPolicies, including L3 restrictions, L4 protocol-specific blocking, and mutual authentication.

### ✅ The actual situation

Let's have a look on the `team-blue` namespace :

```
$ k get all --show-labels -n team-blue -o wide
NAME                         READY   STATUS    RESTARTS   AGE   IP           NODE                 NOMINATED NODE   READINESS GATES   LABELS
pod/app-a-67767c5bd4-njb5f   1/1     Running   0          11m   10.0.1.18    k8s-node01           <none>           <none>            pod-template-hash=67767c5bd4,role=app-a
pod/app-b-84d4c54475-9kqq2   1/1     Running   0          11m   10.0.1.183   k8s-node01           <none>           <none>            pod-template-hash=84d4c54475,role=app-b
pod/app-b-84d4c54475-mkzks   1/1     Running   0          11m   10.0.0.116   k8s-controlplane01   <none>           <none>            pod-template-hash=84d4c54475,role=app-b
pod/app-c-99c764986-mk5w7    1/1     Running   0          11m   10.0.0.29    k8s-controlplane01   <none>           <none>            pod-template-hash=99c764986,role=app-c
pod/app-c-99c764986-z45sl    1/1     Running   0          11m   10.0.1.141   k8s-node01           <none>           <none>            pod-template-hash=99c764986,role=app-c

NAME                TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE   SELECTOR     LABELS
service/service-a   ClusterIP   10.111.234.143   <none>        80/TCP    11m   role=app-a   <none>
service/service-b   ClusterIP   10.100.229.96    <none>        80/TCP    11m   role=app-b   <none>
service/service-c   ClusterIP   10.109.248.32    <none>        80/TCP    11m   role=app-c   <none>

NAME                    READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                    SELECTOR     LABELS
deployment.apps/app-a   1/1     1            1           11m   multitool    wbitt/network-multitool   role=app-a   app=app-a
deployment.apps/app-b   2/2     2            2           11m   multitool    wbitt/network-multitool   role=app-b   app=app-b
deployment.apps/app-c   2/2     2            2           11m   multitool    wbitt/network-multitool   role=app-c   app=app-c

NAME                               DESIRED   CURRENT   READY   AGE   CONTAINERS   IMAGES                    SELECTOR                                  LABELS
replicaset.apps/app-a-67767c5bd4   1         1         1       11m   multitool    wbitt/network-multitool   pod-template-hash=67767c5bd4,role=app-a   pod-template-hash=67767c5bd4,role=app-a
replicaset.apps/app-b-84d4c54475   2         2         2       11m   multitool    wbitt/network-multitool   pod-template-hash=84d4c54475,role=app-b   pod-template-hash=84d4c54475,role=app-b
replicaset.apps/app-c-99c764986    2         2         2       11m   multitool    wbitt/network-multitool   pod-template-hash=99c764986,role=app-c    pod-template-hash=99c764986,role=app-c

```

The `default-allow` CNP :

```yaml
$ k -n team-blue get cnp default-allow -o yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
...
spec:
  egress:
  - toEndpoints:
    - {}
  - toEndpoints:
    - matchLabels:
        io.kubernetes.pod.namespace: kube-system
        k8s-app: kube-dns
    toPorts:
    - ports:
      - port: "53"
        protocol: ANY
      rules:
        dns:
        - matchPattern: '*'
  endpointSelector:
    matchLabels: {}
  ingress:
  - fromEndpoints:
    - {}
```

Let's try some connectivity tests :


- From B to A :

```
$ k -n team-blue exec -it deployments/app-b -- curl http://service-a --max-time 1
WBITT Network MultiTool (with NGINX) - app-a-67767c5bd4-njb5f - 10.0.1.18 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)
```

- Ping from C to POD A (not the service, the internal IP of POD) :

```
$ k -n team-blue exec -it deployments/app-c -- ping 10.0.1.18
PING 10.0.1.18 (10.0.1.18) 56(84) bytes of data.
64 bytes from 10.0.1.18: icmp_seq=1 ttl=63 time=0.954 ms
64 bytes from 10.0.1.18: icmp_seq=2 ttl=63 time=2.08 ms
^C
--- 10.0.1.18 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1048ms
rtt min/avg/max/mdev = 0.954/1.515/2.076/0.561 ms
```

- From A to C :

```
$ k -n team-blue exec -it deployments/app-a -- curl http://service-c --max-time 1
WBITT Network MultiTool (with NGINX) - app-c-99c764986-z45sl - 10.0.1.41 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)
```

### ✅ Step 1: Deny egress (L3 policy)

Create a CiliumNetworkPolicy named `deny-egress-b-to-a`:


```yaml
# deny-egress-b-to-a
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: deny-egress-b-to-a
  namespace: team-blue
spec:
  endpointSelector:
    matchLabels:
      role: app-b
  egressDeny:
  - toEndpoints:
    - matchLabels:
        role: app-a
```

We apply it :

```
$ k apply -f deny-egress-b-to-a.yaml 
ciliumnetworkpolicy.cilium.io/deny-egress-b-to-a created
```


🎯 This will block all egress from Pods labeled `role=app-b` to any Pod with label `role=app-a`, including access via the `service-a` Service.

We can check the rule :

```
$ k -n team-blue describe cnp deny-egress-b-to-a 
Name:         deny-egress-b-to-a
Namespace:    team-blue
Labels:       <none>
Annotations:  <none>
API Version:  cilium.io/v2
Kind:         CiliumNetworkPolicy
Metadata:
  Creation Timestamp:  2025-05-08T11:24:44Z
  Generation:          1
  Resource Version:    46132
  UID:                 5af36318-75e0-407c-a304-085b8816a9d9
Spec:
  Egress Deny:
    To Endpoints:
      Match Labels:
        Role:  app-a
  Endpoint Selector:
    Match Labels:
      Role:  app-b
Status:
  Conditions:
    Last Transition Time:  2025-05-08T11:24:44Z
    Message:               Policy validation succeeded
    Status:                True
    Type:                  Valid
Events:                    <none>
```

Let's check !

```
$ k -n team-blue exec -it deployments/app-b -- curl http://service-a --max-time 1
curl: (28) Connection timed out after 1000 milliseconds
command terminated with exit code 28
```

=> OK !


### ✅ Step 2: Deny ICMP egress (L4 ICMP policy)

Create a policy named `deny-icmp-c-to-a`:

```yaml
# deny-icmp-c-to-a.yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: deny-icmp-c-to-a
  namespace: team-blue
spec:
  endpointSelector:
    matchLabels:
      role: app-c
  egressDeny:
  - toEndpoints:
    - matchLabels:
        role: app-a
    icmps:
    - fields:
      - type: 8
        family: IPv4
      - type: EchoRequest
        family: IPv6
```

We apply it :

```
$ k apply -f deny-icmp-c-to-a.yaml 
ciliumnetworkpolicy.cilium.io/deny-icmp-c-to-a created
```

🎯 This will specifically block ICMP (ping) packets, while still allowing TCP/HTTP from `app-c` to `app-a`.

Let's check now our CNP :

```
$ k -n team-blue exec -it deployments/app-c -- ping 10.0.1.18
PING 10.0.1.18 (10.0.1.18) 56(84) bytes of data.
^C
--- 10.0.1.18 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1002ms

command terminated with exit code 1
```

The ICMP trafic is blocked !

### ✅ Step 3: Require mutual authentication

Create a policy named `require-mtls-a-to-c `:

```yaml
# require-mtls-a-to-c.yaml 
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: require-mtls-a-to-c 
  namespace: team-blue
spec:
  endpointSelector:
    matchLabels:
      role: app-a
  egress:
  - toEndpoints:
    - matchLabels:
        role: app-c
    authentication:
      mode: "required"
```

We apply it :

```
$ k apply -f require-mtls-a-to-c.yaml
ciliumnetworkpolicy.cilium.io/require-mtls-a-to-c created
```

🎯 This requires SPIFFE-based mutual authentication for all traffic from `app-a` Pods to `app-c` Pods. If either end is missing its SPIFFE certificate, the traffic will be blocked.

Let's try a connection from C to A :

```
$ k -n team-blue exec -it deployments/app-a -- curl http://service-c --max-time 1
WBITT Network MultiTool (with NGINX) - app-c-99c764986-z45sl - 10.0.1.41 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)
```
We do a port-forward for *hubble* :

```
$ cilium hubble port-forward &
[1] 6981
ℹ️  Hubble Relay is available at 127.0.0.1:4245
```

Let's have a look on hubble logs :

```
$ sudo hubble observe -n team-blue -f
...
May  8 11:53:23.823: team-blue/app-a-67767c5bd4-njb5f:32940 (ID:9322) -> team-blue/app-c-99c764986-z45sl:80 (ID:51685) policy-verdict:L3-Only EGRESS ALLOWED (TCP Flags: SYN; Auth: SPIRE)
May  8 11:53:23.823: team-blue/app-a-67767c5bd4-njb5f:32940 (ID:9322) -> team-blue/app-c-99c764986-z45sl:80 (ID:51685) policy-verdict:L3-Only INGRESS ALLOWED (TCP Flags: SYN)
```

Notice `Auth: SPIRE` in `policy-verdict:L3-Only EGRESS ALLOWED (TCP Flags: SYN; Auth: SPIRE)` => mTLS ok !

- 💡 `L3-Only` means no L7 inspection (e.g. HTTP) is applied here. Traffic is authorized on the basis of network rules (IP, port, authent).
- ⚠️ This lab assumes that SPIRE and SPIFFE certificates are already properly deployed and mounted. See Cilium's mutual authentication guide for how to configure that.

### 📘 References

* [CiliumNetworkPolicy Reference](https://docs.cilium.io/en/stable/security/policy/language/)
* [Cilium Layer 4 & ICMP rules](https://docs.cilium.io/en/stable/security/policy/language/#limit-icmp-icmpv6-types)
* [Mutual Authentication example (SPIFFE)](https://docs.cilium.io/en/stable/network/servicemesh/mutual-authentication/mutual-authentication-example/#gs-mutual-authentication-example)

---

### ⚠️ Reminder

Be sure to run `reset.sh` when you're done. Leaving mutual auth or deny policies in place may affect other labs.
