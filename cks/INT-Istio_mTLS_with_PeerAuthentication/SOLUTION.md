# ✅ SOLUTION - Enable mTLS with Istio PeerAuthentication

## 🎯 Objective Recap

Enforce mutual TLS (mTLS) between Pods in the `team-app` namespace using Istio.


## ✅ Step 1: Inspect the current state 

```
$ k get ns team-app --show-labels 
NAME              STATUS   AGE     LABELS
team-app          Active   76s     kubernetes.io/metadata.name=team-app

$ k -n team-app get all --show-labels 
NAME                           READY   STATUS    RESTARTS   AGE     LABELS
pod/client-566c4ddbc8-2p4pq    1/1     Running   0          3m59s   app=client,pod-template-hash=566c4ddbc8
pod/httpbin-594fffb6fb-j5mbz   1/1     Running   0          3m59s   app=httpbin,pod-template-hash=594fffb6fb
pod/naked                      1/1     Running   0          3m59s   app=naked,sidecar.istio.io/inject=false

NAME                  TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE     LABELS
service/httpbin-svc   ClusterIP   10.100.146.103   <none>        8080/TCP   3m59s   <none>

NAME                      READY   UP-TO-DATE   AVAILABLE   AGE     LABELS
deployment.apps/client    1/1     1            1           3m59s   <none>
deployment.apps/httpbin   1/1     1            1           3m59s   <none>

NAME                                 DESIRED   CURRENT   READY   AGE     LABELS
replicaset.apps/client-566c4ddbc8    1         1         1       3m59s   app=client,pod-template-hash=566c4ddbc8
replicaset.apps/httpbin-594fffb6fb   1         1         1       3m59s   app=httpbin,pod-template-hash=594fffb6fb
```


## ✅ Step 2: Add label on NS for Sidecar Injection


Doc istio.io > Documentation > Tasks > Security > Authentication > Mutual TLS Migration
- https://istio.io/latest/docs/tasks/security/authentication/mtls-migration/
- First read *Before you begin* section and go the *installation steps* :
  - In Install Istio, you will read :

  2. Add a namespace label to instruct Istio to automatically inject Envoy sidecar proxies when you deploy your application later:
  $ kubectl label namespace default istio-injection=enabled
  namespace/default labeled

So we have to add the label `istio-injection=enabled` in the namespace `team-app` :

```
$ kubectl label namespace team-app istio-injection=enabled
namespace/team-app labeled

$ k get ns team-app --show-labels 
NAME       STATUS   AGE   LABELS
team-app   Active   13m   istio-injection=enabled,kubernetes.io/metadata.name=team-app
```

This ensures all Pods deployed later will get the Istio sidecar (`istio-proxy`) automatically.

We restart the deployments (the manifests are in `~/manifests`) :

```
$ k delete -f manifests/
$ k apply -f manifests/
```

## ✅ Step 3: Verify Sidecars are present

```
$ k -n team-app get pods --show-labels 
NAME                       READY   STATUS    RESTARTS   AGE   LABELS
client-566c4ddbc8-lcwb7    2/2     Running   0          51s   app=client,pod-template-hash=566c4ddbc8,security.istio.io/tlsMode=istio,service.istio.io/canonical-name=client,service.istio.io/canonical-revision=latest
httpbin-594fffb6fb-9kb7j   2/2     Running   0          51s   app=httpbin,pod-template-hash=594fffb6fb,security.istio.io/tlsMode=istio,service.istio.io/canonical-name=httpbin,service.istio.io/canonical-revision=latest
naked                      1/1     Running   0          51s   app=naked
```

We can see now that the pods `client-xxxx` and `httpbin-xxx` have 2 containers, pod `naked`, only one, and we can list them :


```
$ kubectl get pods -n team-app -o jsonpath='{range .items[*]}{.metadata.name}{" → "}{range .spec.containers[*]}{.name}{","}{end}{"\n"}{end}'
client-566c4ddbc8-lcwb7 → client,istio-proxy,
httpbin-594fffb6fb-9kb7j → httpbin,istio-proxy,
naked → curl,
```

The new containers are named `istio-proxy`, and they have been injected automatically by Istio => ✅ The sidecar injection is Ok ! 

We notice that the pod `naked` has no `istio-proxy` container because of its label :

```yaml
...
metadata:
  name: naked
  ...
  labels:
    sidecar.istio.io/inject: "false"
```

We can see in a pod, for instance httpbin

```
$ k -n team-app describe pod/httpbin-594fffb6fb-9kb7j 
Name:             httpbin-594fffb6fb-9kb7j
Namespace:        team-app
Priority:         0
Service Account:  default
Node:             k8s-controlplane01/192.168.1.200
Start Time:       Wed, 30 Apr 2025 13:45:31 +0000
Labels:           app=httpbin
                  pod-template-hash=594fffb6fb
                  security.istio.io/tlsMode=istio
                  service.istio.io/canonical-name=httpbin
                  service.istio.io/canonical-revision=latest
Annotations:      istio.io/rev: default
                  kubectl.kubernetes.io/default-container: httpbin
                  kubectl.kubernetes.io/default-logs-container: httpbin
                  prometheus.io/path: /stats/prometheus
                  prometheus.io/port: 15020
                  prometheus.io/scrape: true
                  sidecar.istio.io/status:
                    {"initContainers":["istio-init"],"containers":["istio-proxy"],"volumes":["workload-socket","credential-socket","workload-certs","istio-env...
Status:           Running
IP:               10.0.0.248
IPs:
  IP:           10.0.0.248
Controlled By:  ReplicaSet/httpbin-594fffb6fb
Init Containers:
  istio-init:
    Container ID:  containerd://ad697ea7db158b6a16cdb6806a3e9cf3896d399ca187aa44139989b400ae57f9
    Image:         docker.io/istio/proxyv2:1.25.2
    Image ID:      docker.io/istio/proxyv2@sha256:49ed9dd2c06383c0a847877a707a3563d0968d83779ad8d13a0c022a48c5c407
    Port:          <none>
    Host Port:     <none>
    Args:
      istio-iptables
      -p
      15001
      -z
      15006
      -u
      1337
      -m
      REDIRECT
      -i
      *
      -x
      
      -b
      *
      -d
      15090,15021,15020
      --log_output_level=default:info
    State:          Terminated
      Reason:       Completed
      Exit Code:    0
      Started:      Wed, 30 Apr 2025 13:45:32 +0000
      Finished:     Wed, 30 Apr 2025 13:45:32 +0000
    Ready:          True
    Restart Count:  0
    Limits:
      cpu:     2
      memory:  1Gi
    Requests:
      cpu:        100m
      memory:     128Mi
    Environment:  <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-6jnvh (ro)
Containers:
  httpbin:
    Container ID:   containerd://2d27dff09ab1ac5b167d805ca5a2fa1c2bc9e5cd2c94cf99c7af1498d538aba9
    Image:          docker.io/mccutchen/go-httpbin
    Image ID:       docker.io/mccutchen/go-httpbin@sha256:ff73c96c144506048b1357ada7015b3473adc1d5bebc7088bc389bf5e64e114f
    Port:           8080/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Wed, 30 Apr 2025 13:45:35 +0000
    Ready:          True
    Restart Count:  0
    Environment:
      HTTPBIN_ENV_GREETINGS:  Hello from go-httpbin
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-6jnvh (ro)
  istio-proxy:
    Container ID:  containerd://8ad7bdac9012af704452543a45872d1e7d3cbbca6d9769a50da9e2218e878b77
    Image:         docker.io/istio/proxyv2:1.25.2
    Image ID:      docker.io/istio/proxyv2@sha256:49ed9dd2c06383c0a847877a707a3563d0968d83779ad8d13a0c022a48c5c407
    Port:          15090/TCP
    Host Port:     0/TCP
    Args:
      proxy
      sidecar
      --domain
      $(POD_NAMESPACE).svc.cluster.local
      --proxyLogLevel=warning
      --proxyComponentLogLevel=misc:error
      --log_output_level=default:info
    State:          Running
      Started:      Wed, 30 Apr 2025 13:45:35 +0000
    Ready:          True
    Restart Count:  0
    Limits:
      cpu:     2
      memory:  1Gi
    Requests:
      cpu:      100m
      memory:   128Mi
    Readiness:  http-get http://:15021/healthz/ready delay=0s timeout=3s period=15s #success=1 #failure=4
    Startup:    http-get http://:15021/healthz/ready delay=0s timeout=3s period=1s #success=1 #failure=600
    Environment:
      PILOT_CERT_PROVIDER:           istiod
      CA_ADDR:                       istiod.istio-system.svc:15012
      POD_NAME:                      httpbin-594fffb6fb-9kb7j (v1:metadata.name)
      POD_NAMESPACE:                 team-app (v1:metadata.namespace)
      INSTANCE_IP:                    (v1:status.podIP)
      SERVICE_ACCOUNT:                (v1:spec.serviceAccountName)
      HOST_IP:                        (v1:status.hostIP)
      ISTIO_CPU_LIMIT:               2 (limits.cpu)
      PROXY_CONFIG:                  {}
                                     
      ISTIO_META_POD_PORTS:          [
                                         {"containerPort":8080,"protocol":"TCP"}
                                     ]
      ISTIO_META_APP_CONTAINERS:     httpbin
      GOMEMLIMIT:                    1073741824 (limits.memory)
      GOMAXPROCS:                    2 (limits.cpu)
      ISTIO_META_CLUSTER_ID:         Kubernetes
      ISTIO_META_NODE_NAME:           (v1:spec.nodeName)
      ISTIO_META_INTERCEPTION_MODE:  REDIRECT
      ISTIO_META_WORKLOAD_NAME:      httpbin
      ISTIO_META_OWNER:              kubernetes://apis/apps/v1/namespaces/team-app/deployments/httpbin
      ISTIO_META_MESH_ID:            cluster.local
      TRUST_DOMAIN:                  cluster.local
    Mounts:
      /etc/istio/pod from istio-podinfo (rw)
      /etc/istio/proxy from istio-envoy (rw)
      /var/lib/istio/data from istio-data (rw)
      /var/run/secrets/credential-uds from credential-socket (rw)
      /var/run/secrets/istio from istiod-ca-cert (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-6jnvh (ro)
      /var/run/secrets/tokens from istio-token (rw)
      /var/run/secrets/workload-spiffe-credentials from workload-certs (rw)
      /var/run/secrets/workload-spiffe-uds from workload-socket (rw)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       True 
  ContainersReady             True 
  PodScheduled                True 
Volumes:
  workload-socket:
    Type:       EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:     
    SizeLimit:  <unset>
  credential-socket:
    Type:       EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:     
    SizeLimit:  <unset>
  workload-certs:
    Type:       EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:     
    SizeLimit:  <unset>
  istio-envoy:
    Type:       EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:     Memory
    SizeLimit:  <unset>
  istio-data:
    Type:       EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:     
    SizeLimit:  <unset>
  istio-podinfo:
    Type:  DownwardAPI (a volume populated by information about the pod)
    Items:
      metadata.labels -> labels
      metadata.annotations -> annotations
  istio-token:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  43200
  istiod-ca-cert:
    Type:      ConfigMap (a volume populated by a ConfigMap)
    Name:      istio-ca-root-cert
    Optional:  false
  kube-api-access-6jnvh:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   Burstable
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age    From               Message
  ----    ------     ----   ----               -------
  Normal  Scheduled  9m20s  default-scheduler  Successfully assigned team-app/httpbin-594fffb6fb-9kb7j to k8s-controlplane01
  Normal  Pulled     9m19s  kubelet            Container image "docker.io/istio/proxyv2:1.25.2" already present on machine
  Normal  Created    9m19s  kubelet            Created container: istio-init
  Normal  Started    9m19s  kubelet            Started container istio-init
  Normal  Pulling    9m19s  kubelet            Pulling image "docker.io/mccutchen/go-httpbin"
  Normal  Pulled     9m16s  kubelet            Successfully pulled image "docker.io/mccutchen/go-httpbin" in 2.532s (2.532s including waiting). Image size: 16874333 bytes.
  Normal  Created    9m16s  kubelet            Created container: httpbin
  Normal  Started    9m16s  kubelet            Started container httpbin
  Normal  Pulled     9m16s  kubelet            Container image "docker.io/istio/proxyv2:1.25.2" already present on machine
  Normal  Created    9m16s  kubelet            Created container: istio-proxy
  Normal  Started    9m16s  kubelet            Started container istio-proxy
```

## ✅ Step 4: Apply PeerAuthentication Policy

Doc istio.io > Documentation > Tasks > Security > Authentication > Mutual TLS Migration
- https://istio.io/latest/docs/tasks/security/authentication/mtls-migration/#lock-down-to-mutual-tls-by-namespace


Create `peerauth-strict.yaml` and copy this manifest manually :

```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: mutual-tls-auth
  namespace: team-app # Only for the namespace team-app (for the entire mesh, it's istio-system - see doc)
spec:
  mtls:
    mode: STRICT
```

```bash
$ kubectl apply -f peerauth-strict.yaml
peerauthentication.security.istio.io/mutual-tls-auth created
```

This enforces **strict mTLS** between all workloads in the `team-app` namespace.

We can see :

```
$ kubectl get peerauthentication --all-namespaces
NAMESPACE   NAME              MODE     AGE
team-app    mutual-tls-auth   STRICT   35s

$ kubectl -n team-app describe peerauthentications.security.istio.io mutual-tls-auth 
Name:         mutual-tls-auth
Namespace:    team-app
Labels:       <none>
Annotations:  <none>
API Version:  security.istio.io/v1
Kind:         PeerAuthentication
Metadata:
  Creation Timestamp:  2025-04-30T13:57:46Z
  Generation:          1
  Resource Version:    49901
  UID:                 74ffb022-4e04-45ec-af62-16af24548bdc
Spec:
  Mtls:
    Mode:  STRICT
Events:    <none>
```

---

## ✅ Step 5: Verify Communication

### With sidecar-enabled `client`:

```
$ kubectl exec -n team-app deploy/client -- curl -s http://httpbin-svc:8080/env
{
  "env": {
    "HTTPBIN_ENV_GREETINGS": "Hello from go-httpbin"
  }
}

```
➡️ Response: JSON with headers → ✅ works

### With a Pod that has **no sidecar** (manual or manifest test):

You can test with naked Pod :

Wait for it to start, then:

```
$ kubectl exec -n team-app pod/naked -- curl -s http://httpbin-svc:8080/env
command terminated with exit code 56
```

- Note : exit code 56 = "Failure in receiving network data" (often rejected TLS handshake)

➡️ Expected: ❌ Connection fails because no mTLS handshake is possible 

## ✅ mTLS Communication Verification Matrix

| Pod Name        | Has Sidecar | Command Example                                                   | Expected Result         |
|------------------|-------------|--------------------------------------------------------------------|--------------------------|
| `client`          | ✅ Yes      | `kubectl exec -n team-app deploy/client -- curl http://httpbin-svc:8080/get` | ✅ HTTP 200 OK (mTLS handshake OK) |
| `naked`          | ❌ No       | `kubectl exec -n team-app pod/naked -- curl http://httpbin-svc:8080/get`     | ❌ Connection fails (mTLS handshake missing) |

---

## 🧠 How It Works

- The `PeerAuthentication` resource tells Istio to require **mTLS** for all communication in STRICT mode.
- The `istio-proxy` sidecar in each Pod automatically handles TLS handshake, certs, and encryption.
- Any Pod without a sidecar will **not participate in the mTLS handshake**, and the connection will be rejected.


## 🔐 Bonus: Additional Layer with AuthorizationPolicy (FYI only)

While `PeerAuthentication` ensures that mutual TLS (mTLS) is required between workloads, it does **not** define *who* is allowed to talk to *whom*. That’s where `AuthorizationPolicy` comes in.

An `AuthorizationPolicy` lets you define fine-grained access control rules **after** mTLS has been established. For example, you can allow only specific workloads (based on labels, namespaces, ports, etc.) to reach a service — even if they have a valid mTLS connection.

→ **Example use cases:**
- Allow only `client` to access `httpbin` on port 8080.
- Deny all traffic to `httpbin` unless explicitly allowed.

📌 You will practice this in a **follow-up lab** focused on Istio `AuthorizationPolicy`.


## 🛠️ Optional: Install and Use `istioctl`

If Istio was installed using Helm, the `istioctl` CLI may not be present by default. This CLI is useful for analyzing configuration and troubleshooting issues.

### ➕ To install `istioctl`:

```bash
$ curl -L https://istio.io/downloadIstio | sh -
$ sudo mv istio-*/bin/istioctl /usr/local/bin/
```

Verify the version:

```
$ istioctl version
client version: 1.25.2
control plane version: 1.25.2
data plane version: 1.25.2 (2 proxies)
```

#### 🔪 Helpful commands:

- 🔍 **View configuration pushed to a proxy**
```bash
istioctl proxy-config listeners <pod>.<namespace>
istioctl proxy-config clusters <pod>.<namespace>
istioctl proxy-config routes <pod>.<namespace>
```

- 🪵 **Get Envoy log level**

```bash
istioctl proxy-config log <pod>.<namespace> 
```

Example :

```
$ istioctl proxy-config log httpbin-594fffb6fb-9kb7j.team-app 
httpbin-594fffb6fb-9kb7j.team-app:
active loggers:
  admin: warning
  alternate_protocols_cache: warning
  aws: warning
  assert: warning
  backtrace: warning
  basic_auth: warning
  cache_filter: warning
  client: warning
  config: warning
...
```

- 🪵 **Change Envoy log level (runtime)**
```bash
istioctl proxy-config log <pod>.<namespace> --level debug
```
Or for specific subsystems:
```bash
istioctl proxy-config log <pod>.<namespace> --level connection:debug,router:info
```
Example :

```
$ istioctl proxy-config log httpbin-594fffb6fb-9kb7j.team-app --level debug
httpbin-594fffb6fb-9kb7j.team-app:
active loggers:
  admin: debug
  alternate_protocols_cache: debug
  aws: debug
  assert: debug
  backtrace: debug
```

- **Check sidecar injection status:**

```
$ istioctl proxy-status
NAME                                  CLUSTER        CDS              LDS              EDS              RDS              ECDS        ISTIOD                      VERSION
client-566c4ddbc8-lcwb7.team-app      Kubernetes     SYNCED (29m)     SYNCED (29m)     SYNCED (29m)     SYNCED (29m)     IGNORED     istiod-5945c7b655-zbrkj     1.25.2
httpbin-594fffb6fb-9kb7j.team-app     Kubernetes     SYNCED (23m)     SYNCED (23m)     SYNCED (23m)     SYNCED (23m)     IGNORED     istiod-5945c7b655-zbrkj     1.25.2
```

- **Analyze Istio configuration and detect potential issues:**

```
$ istioctl analyze -A
Info [IST0102] (Namespace cilium-secrets) The namespace is not enabled for Istio injection. Run 'kubectl label namespace cilium-secrets istio-injection=enabled' to enable it, or 'kubectl label namespace cilium-secrets istio-injection=disabled' to explicitly mark it as not needing injection.
Info [IST0102] (Namespace default) The namespace is not enabled for Istio injection. Run 'kubectl label namespace default istio-injection=enabled' to enable it, or 'kubectl label namespace default istio-injection=disabled' to explicitly mark it as not needing injection.
Info [IST0102] (Namespace kube-node-lease) The namespace is not enabled for Istio injection. Run 'kubectl label namespace kube-node-lease istio-injection=enabled' to enable it, or 'kubectl label namespace kube-node-lease istio-injection=disabled' to explicitly mark it as not needing injection
...
```

- 🔍 **View configuration pushed to a proxy**
```bash
istioctl proxy-config listeners <pod>.<namespace>
istioctl proxy-config clusters <pod>.<namespace>
istioctl proxy-config routes <pod>.<namespace>
```

Example :

```
$ istioctl proxy-config listeners httpbin-594fffb6fb-9kb7j.team-app
ADDRESSES     PORT  MATCH                                                   DESTINATION
10.96.0.10    53    ALL                                                     Cluster: outbound|53||kube-dns.kube-system.svc.cluster.local
10.103.240.24 443   ALL                                                     Cluster: outbound|443||istiod.istio-system.svc.cluster.local
10.96.0.1     443   ALL                                                     Cluster: outbound|443||kubernetes.default.svc.cluster.local
10.97.112.249 443   Trans: raw_buffer; App: http/1.1,h2c                    Route: hubble-peer.kube-system.svc.cluster.local:443
10.97.112.249 443   ALL                                                     Cluster: outbound|443||hubble-peer.kube-system.svc.cluster.local
0.0.0.0       8080  Trans: raw_buffer; App: http/1.1,h2c                    Route: 8080
0.0.0.0       8080  ALL                                                     PassthroughCluster
10.96.0.10    9153  Trans: raw_buffer; App: http/1.1,h2c                    Route: kube-dns.kube-system.svc.cluster.local:9153
10.96.0.10    9153  ALL                                                     Cluster: outbound|9153||kube-dns.kube-system.svc.cluster.local
192.168.1.200 9964  Trans: raw_buffer; App: http/1.1,h2c                    Route: cilium-envoy.kube-system.svc.cluster.local:9964
192.168.1.200 9964  ALL                                                     Cluster: outbound|9964||cilium-envoy.kube-system.svc.cluster.local
192.168.1.201 9964  Trans: raw_buffer; App: http/1.1,h2c                    Route: cilium-envoy.kube-system.svc.cluster.local:9964
192.168.1.201 9964  ALL                                                     Cluster: outbound|9964||cilium-envoy.kube-system.svc.cluster.local
0.0.0.0       15001 ALL                                                     PassthroughCluster
0.0.0.0       15001 Addr: *:15001                                           Non-HTTP/Non-TCP
0.0.0.0       15006 Addr: *:15006                                           Non-HTTP/Non-TCP
0.0.0.0       15006 Trans: tls; App: istio-http/1.0,istio-http/1.1,istio-h2 InboundPassthroughCluster
0.0.0.0       15006 Trans: tls                                              InboundPassthroughCluster
0.0.0.0       15006 Trans: tls; Addr: *:8080                                Cluster: inbound|8080||
0.0.0.0       15010 Trans: raw_buffer; App: http/1.1,h2c                    Route: 15010
0.0.0.0       15010 ALL                                                     PassthroughCluster
10.103.240.24 15012 ALL                                                     Cluster: outbound|15012||istiod.istio-system.svc.cluster.local
0.0.0.0       15014 Trans: raw_buffer; App: http/1.1,h2c                    Route: 15014
0.0.0.0       15014 ALL                                                     PassthroughCluster
0.0.0.0       15021 ALL                                                     Inline Route: /healthz/ready*
0.0.0.0       15090 ALL                                                     Inline Route: /stats/prometheus*

```

> 🧠 Tip: These tools are especially helpful during the exam to quickly validate configuration or debug policy issues.






















## 🔎 Troubleshooting Tips

- Check if sidecar is missing:
  ```bash
  kubectl get pod -n team-app -o jsonpath='{.spec.containers[*].name}'
  ```
- Check Istio logs:
  ```bash
  kubectl logs -n istio-system -l app=istiod
  ```
- Disable auto-injection for a Pod using:
  ```yaml
  sidecar.istio.io/inject: "false"
  ```

---

## 📘 References

- [Istio PeerAuthentication](https://istio.io/latest/docs/reference/config/security/peer_authentication/)
- [Istio mTLS concepts](https://istio.io/latest/docs/tasks/security/authentication/mtls-migration/)
- [CKS Exam Topics](https://github.com/cncf/curriculum/blob/main/CKS_Curriculum_V1.0.md)

