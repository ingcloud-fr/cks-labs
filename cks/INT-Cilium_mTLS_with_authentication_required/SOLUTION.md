# ✅ SOLUTION - Enforce Cilium Mutual Authentication

## 🌟 Objective Recap

Create a Cilium policy that enforces authentication on a sensitive backend service, ensuring that only trusted clients using mTLS can communicate with it.

## 📌 Notes about Cilium mTLS

In Cilium’s current mutual authentication support, identity management is provided through the use of **SPIFFE** (*Secure Production Identity Framework for Everyone*).

Cilium was installed during the cluster bootup and was deployed with the following *Helm* flags (see scripts in *vcluster*):

```yaml
authentication:
  mutual:
    spire:
      enabled: true
      install:
        enabled: true
```

This enabled the mutual authentication feature and automatically deployed a **SPIRE server**.

https://docs.cilium.io/en/stable/network/servicemesh/mutual-authentication/mutual-authentication/

You should have :

```yaml
$ kubectl -n kube-system get configmap cilium-config -o yaml | grep mesh-auth
  mesh-auth-enabled: "true"
  mesh-auth-gc-interval: 5m0s
  mesh-auth-mutual-connect-timeout: 5s
  mesh-auth-mutual-enabled: "true"
  mesh-auth-mutual-listener-port: "4250"
  mesh-auth-queue-size: "1024"
  mesh-auth-rotated-identities-queue-size: "1024"
  mesh-auth-spiffe-trust-domain: spiffe.cilium
  mesh-auth-spire-admin-socket: /run/spire/sockets/admin.sock
  mesh-auth-spire-agent-socket: /run/spire/sockets/agent/agent.sock
  mesh-auth-spire-server-address: spire-server.cilium-spire.svc:8081
  mesh-auth-spire-server-connection-timeout: 30s
```

The spire server should be ok :

```
$ kubectl exec -n cilium-spire spire-server-0 -c spire-server -- /opt/spire/bin/spire-server healthcheck
Server is healthy.
```

We can see in the namespace `cilium-spire` the `spire-server` and its agents:

```
$ k -n cilium-spire get all -o wide
NAME                    READY   STATUS    RESTARTS   AGE   IP              NODE                 NOMINATED NODE   READINESS GATES
pod/spire-agent-b442p   1/1     Running   0          22m   192.168.1.200   k8s-controlplane01   <none>           <none>
pod/spire-agent-w7mk8   1/1     Running   0          19m   192.168.1.201   k8s-node01           <none>           <none>
pod/spire-server-0      2/2     Running   0          22m   10.0.0.128      k8s-controlplane01   <none>           <none>

NAME                   TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE   SELECTOR
service/spire-server   ClusterIP   10.106.222.209   <none>        8081/TCP   22m   app=spire-server

NAME                         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE   CONTAINERS    IMAGES                                                                                                     SELECTOR
daemonset.apps/spire-agent   2         2         2       2            2           <none>          22m   spire-agent   ghcr.io/spiffe/spire-agent:1.9.6@sha256:5106ac601272a88684db14daf7f54b9a45f31f77bb16a906bd5e87756ee7b97c   app=spire-agent

NAME                            READY   AGE   CONTAINERS                 IMAGES
statefulset.apps/spire-server   1/1     22m   cilium-init,spire-server   docker.io/library/busybox:1.37.0@sha256:37f7b378a29ceb4c551b1b5582e27747b855bbfaa73fa11914fe0df028dc581f,ghcr.io/spiffe/spire-server:1.9.6@sha256:59a0b92b39773515e25e68a46c40d3b931b9c1860bc445a79ceb45a805cab8b4
```

The spire server default installation requires `PersistentVolumeClaim` support in the cluster, so in this lab we set a PV `pv-spire`. We can see that the PV `spire-pv` is `Bound` :

```
$ k get pv
NAME       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                    STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
spire-pv   1Gi        RWO            Retain           Bound    cilium-spire/spire-data-spire-server-0                  <unset>                          7m
```

We can see the spire agents (1 per node) :

```
$ kubectl exec -n cilium-spire spire-server-0 -c spire-server -- /opt/spire/bin/spire-server agent list
Found 2 attested agents:

SPIFFE ID         : spiffe://spiffe.cilium/spire/agent/k8s_psat/default/12813b9c-6e5e-431f-8bed-076130d7f2c9
Attestation type  : k8s_psat
Expiration time   : 2025-05-01 19:21:03 +0000 UTC
Serial number     : 80402190152711078340651011323549137271
Can re-attest     : true

SPIFFE ID         : spiffe://spiffe.cilium/spire/agent/k8s_psat/default/a7fea58e-d32c-4c36-b0f1-435320ac26af
Attestation type  : k8s_psat
Expiration time   : 2025-05-01 19:23:49 +0000 UTC
Serial number     : 57492655195279155568800087562881232144
Can re-attest     : true
```


## ✅ Step-by-step Resolution

### ✅ Step 1: Understand the topology

From the lab description:
- Namespace: `team-yellow`
- Pods:
  - `server`: backend pod that must be protected
  - `client`: should be allowed
  - `untrusted`: should be blocked


### ✅ Exploration

For the lab, first, we set the debug mode :

```
$ cilium config set debug true
✨ Patching ConfigMap cilium-config with debug=true...
♻️  Restarted Cilium pods


$ cilium config view | grep debug
debug             true
debug-verbose                    
```

Let's have a look on what we have, especially the *labels* :

```
$ k -n team-yellow get all --show-labels 
NAME            READY   STATUS    RESTARTS   AGE     LABELS
pod/client      1/1     Running   0          5m21s   app=client
pod/server      1/1     Running   0          5m21s   run=server
pod/untrusted   1/1     Running   0          5m21s   app=untrusted

NAME             TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE     LABELS
service/server   ClusterIP   10.111.91.224   <none>        8080/TCP   5m21s   <none>
```

We can test :

```
$ k -n team-yellow exec -it pod/client -- curl -XPOST http://server:8080/anything --max-time 1
{
  "args": {},
 ...
  "method": "POST",
...
}

$ k -n team-yellow exec -it pod/client -- curl -XGET http://server:8080/anything --max-time 1
{
  "args": {},
 ...
  "method": "GET",
...
}

$ k -n team-yellow exec -it pod/untrusted -- curl -XPOST http://server:8080/anything --max-time 1
{
  "args": {},
 ...
  "method": "POST",
...
}


$ k -n team-yellow exec -it pod/untrusted -- curl -XGET http://server:8080/anything --max-time 1
{
  "args": {},
 ...
  "method": "GET",
...
}
```

Ok everything work, no restriction !

### ✅ First Policy Example (without mutual authentication)

We will check the log with Hubble (Hubble already is installed)

So, we have to forward the Hub Relay port on the local machine :

```
$ cilium hubble port-forward &
[1] 38846
ℹ️  Hubble Relay is available at 127.0.0.1:4245
```

Let's begin with a L7 rule without mutual authentification

```yaml
# cnp.yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: enforce-access
  namespace: team-yellow
spec:
  endpointSelector:
    matchLabels:
      run: server
  ingress:
  - fromEndpoints:
    - matchLabels:
        app: client
    toPorts:
    - ports:
      - port: "8080"
        protocol: TCP
      rules:
        http:
        - method: "POST"
          path: "/anything"
```

```
$ k apply -f cnp.yaml 
ciliumnetworkpolicy.cilium.io/enforce-access created
```

Let's do the same tests again :


The first test :

```
$ k -n team-yellow exec -it pod/client -- curl -XPOST http://server:8080/anything --max-time 1
{
  "args": {},
 ...
  "method": "POST",
...
}
```


```
$ hubble observe -n team-yellow
...
May  2 15:07:19.582: team-yellow/client:50770 (ID:26244) -> team-yellow/server:8080 (ID:15345) policy-verdict:L3-L4 INGRESS ALLOWED (TCP Flags: SYN)
...
May  2 15:07:19.601: team-yellow/client:50770 (ID:26244) -> team-yellow/server:8080 (ID:15345) http-request FORWARDED (HTTP/1.1 POST http://server:8080/anything)
May  2 15:07:19.601: team-yellow/client:50770 (ID:26244) <- team-yellow/server:8080 (ID:15345) http-response FORWARDED (HTTP/1.1 200 0ms (POST http://server:8080/anything))
```

We can see :

```
May  2 15:07:19.582: team-yellow/client:50770 (ID:26244) -> team-yellow/server:8080 (ID:15345) policy-verdict:L3-L4 INGRESS ALLOWED (TCP Flags: SYN)
```

The second test :

```
$ k -n team-yellow exec -it pod/client -- curl -XGET http://server:8080/anything --max-time 1
Access denied
```

In the log :

```
$ hubble observe -n team-yellow
...
May  2 15:10:22.114: team-yellow/client:45984 (ID:26244) -> team-yellow/server:8080 (ID:15345) policy-verdict:L3-L4 INGRESS ALLOWED (TCP Flags: SYN)
...
May  2 15:10:22.118: team-yellow/client:45984 (ID:26244) -> team-yellow/server:8080 (ID:15345) http-request DROPPED (HTTP/1.1 GET http://server:8080/anything)
May  2 15:10:22.118: team-yellow/client:45984 (ID:26244) <- team-yellow/server:8080 (ID:15345) http-response FORWARDED (HTTP/1.1 403 0ms (GET http://server:8080/anything))
```

- The L3-L4 layer allows the request : `policy-verdict:L3-L4 INGRESS ALLOWED (TCP Flags: SYN)`
- But the L7 dropped it : `http-request DROPPED (HTTP/1.1 GET http://server:8080/anything)`


The third test :

```
$ k -n team-yellow exec -it pod/untrusted -- curl -XPOST http://server:8080/anything --max-time 1
curl: (28) Connection timed out after 1002 milliseconds
command terminated with exit code 28
```

The logs :

```
$ hubble observe -n team-yellow
...
May  2 15:14:00.022: team-yellow/untrusted:42472 (ID:1282) <> team-yellow/server:8080 (ID:15345) policy-verdict:none INGRESS DENIED (TCP Flags: SYN)
May  2 15:14:00.022: team-yellow/untrusted:42472 (ID:1282) <> team-yellow/server:8080 (ID:15345) Policy denied DROPPED (TCP Flags: SYN)
```

- The L3-L4 layer rejected the connexion

The fourth test :


```
$ k -n team-yellow exec -it pod/untrusted -- curl -XGET http://server:8080/anything --max-time 1
curl: (28) Connection timed out after 1002 milliseconds
command terminated with exit code 28
```

```
$ hubble observe -n team-yellow
...
May  2 15:17:00.980: team-yellow/untrusted:35284 (ID:1282) <> team-yellow/server:8080 (ID:15345) policy-verdict:none INGRESS DENIED (TCP Flags: SYN)
May  2 15:17:00.980: team-yellow/untrusted:35284 (ID:1282) <> team-yellow/server:8080 (ID:15345) Policy denied DROPPED (TCP Flags: SYN)
```

- The same as previous, the L3-L4 layer rejected the connexion


### ✅ Final Policy Example (with mutual authentication)


Search for *authentication* in Ciliul documentation : 
- https://docs.cilium.io/en/stable/network/servicemesh/mutual-authentication/mutual-authentication-example/#enforce-mutual-authentication

We define a policy that allows ingress *only* from authenticated sources. To enforce this, we add:

```yaml
authentication:
  mode: "required"
```

This ensures mutual TLS is **required** between the client and the server pod.


```yaml
# cnp.yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: enforce-access
  namespace: team-yellow
spec:
  endpointSelector:
    matchLabels:
      run: server
  ingress:
  - fromEndpoints:
    - matchLabels:
        app: client
    authentication:    # ADD
      mode: "required" # ADD
    toPorts:
    - ports:
      - port: "8080"
        protocol: TCP
      rules:
        http:
        - method: "POST"
          path: "/anything"
```

```
$ k apply -f cnp.yaml
ciliumnetworkpolicy.cilium.io/enforce-access configured
```

Let do some tests and check the hubble logs !

The first test :

```
$ k -n team-yellow exec -it pod/client -- curl -XPOST http://server:8080/anything --max-time 1
{
  "args": {},
 ...
  "method": "POST",
...
}
```

And the logs :

```
$ hubble observe -n team-yellow --since 3m
...
May  2 15:37:29.469: team-yellow/client:58312 (ID:26244) -> team-yellow/server:8080 (ID:15345) policy-verdict:L3-L4 INGRESS ALLOWED (TCP Flags: SYN; Auth: SPIRE)
...
May  2 15:37:29.489: team-yellow/client:58312 (ID:26244) <- team-yellow/server:8080 (ID:15345) http-response FORWARDED (HTTP/1.1 200 17ms (POST http://server:8080/anything))
```

- Notice the `Auth: SPIRE` in `policy-verdict:L3-L4 INGRESS ALLOWED (TCP Flags: SYN; Auth: SPIRE)` which means that the authentication is ok

Note : If you test too quicky after applying the rule, you might get (and it's ok a few second later) :

```
$ k -n team-yellow exec -it pod/client -- curl -XPOST http://server:8080/anything --max-time 1
curl: (28) Connection timed out after 1002 milliseconds
command terminated with exit code 28
```

- The spire agent did not have enought time to give an id so the rule rejects the connexion because of the auth :

```
May  2 15:28:35.455: team-yellow/client:59314 (ID:26244) <> team-yellow/server:8080 (ID:15345) policy-verdict:L3-L4 INGRESS DENIED (TCP Flags: SYN; Auth: SPIRE)
May  2 15:28:35.455: team-yellow/client:59314 (ID:26244) <> team-yellow/server:8080 (ID:15345) Authentication required DROPPED (TCP Flags: SYN)
```

The second test :


```
$ k -n team-yellow exec -it pod/client -- curl -XGET http://server:8080/anything --max-time 1
Access denied
```

The logs:

```
$ hubble observe -n team-yellow --since 3m
...
May  2 15:46:26.108: team-yellow/client:52608 (ID:26244) -> team-yellow/server:8080 (ID:15345) policy-verdict:L3-L4 INGRESS ALLOWED (TCP Flags: SYN; Auth: SPIRE)
...
May  2 15:46:26.112: team-yellow/client:52608 (ID:26244) -> team-yellow/server:8080 (ID:15345) http-request DROPPED (HTTP/1.1 GET http://server:8080/anything)
May  2 15:46:26.112: team-yellow/client:52608 (ID:26244) <- team-yellow/server:8080 (ID:15345) http-response FORWARDED (HTTP/1.1 403 0ms (GET http://server:8080/anything))
```

- The auth is ok but the connxion is rejected by the L7 rule

The third (and the fourth, because result is the same) test :

```
$ k -n team-yellow exec -it pod/untrusted -- curl -XPOST http://server:8080/anything --max-time 1
curl: (28) Connection timed out after 1002 milliseconds
command terminated with exit code 28
```

The logs :

```
May  2 15:48:20.563: team-yellow/untrusted:44556 (ID:1282) <> team-yellow/server:8080 (ID:15345) policy-verdict:none INGRESS DENIED (TCP Flags: SYN)
May  2 15:48:20.563: team-yellow/untrusted:44556 (ID:1282) <> team-yellow/server:8080 (ID:15345) Policy denied DROPPED (TCP Flags: SYN)

```

- The layer L3-L4 dropped the connexion before the authentication (there is no `Auth: SPIRE`)

🏁 So the L3-L4 + L7 with mTLS is OK !!


## Change the path in CNP rule to allow `/anything?foo=bar`

If we add string after the URL like `?foo=bar`, the access is denied

```
$ k -n team-yellow exec -it pod/client -- curl -XPOST http://server:8080/anything?foo=bar --max-time 1
Access denied
```

We have to change the path (which is stric) with a regex :

```yaml
      rules:
        http:
        - method: "POST"
          path: "/anything"
```

to :

```yaml
      rules:
        http:
        - method: "POST"
          path: "^/anything($|\\?.*)"
```

```
$ k -n team-yellow exec -it pod/client -- curl -XPOST http://server:8080/anything?foo=bar --max-time 1
{
  "args": {
    "foo": [
      "bar"
    ]
...
  "method": "POST",
  "url": "http://server:8080/anything?foo=bar",
}
```

Note : to also allow `/anything/123/` change path to `path: "^/post(/.*)?(\\?.*)?$"`

## 🔎 Useful References
- Cilium Authentication Docs: https://docs.cilium.io/en/stable/network/servicemesh/mutual-authentication/mutual-authentication-example/

## 📄 Tips
- Authentication-based policies require the Cilium mTLS identity-aware infrastructure.
- Always ensure that `authentication.mode: required` is inside the correct `ingress` or `egress` rule.

