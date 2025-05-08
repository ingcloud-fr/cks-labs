# 🔐 Accessing and Protecting Secrets in etcd

This lab demonstrates how to:

1. 🔍 Read raw Secret content directly from etcd
2. 📂 Decode and extract specific data fields from a Secret
3. 🛡️ Enable **encryption at rest** for Kubernetes *Secrets* and *ConfigMaps* using an *EncryptionConfiguration* file

---

## 🧪 Step 1 - Extracting a Secret from etcd

Search for **data at rest** in kubernetes documentation and go to the *Verifying that data is encrypted* section for example :
- https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/#verifying-that-data-is-encrypted

Retrieve the raw data stored in etcd for the Secret named `database-password` in the namespace `team-blue`.

First, we need to get the certs and key and as the kube-apiserver uses them to connect to the ETCD server, we can search in its configuration file :

```
$ sudo grep etcd /etc/kubernetes/manifests/kube-apiserver.yaml
    - --etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt
    - --etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt
    - --etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key
    - --etcd-servers=https://127.0.0.1:2379
```

Then we will use them in *etcdctl* command.
As ETCD in Kubernetes stores data under /registry/{type}/{namespace}/{name}, we can use the following command :

```
$ sudo ETCDCTL_API=3 etcdctl \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/apiserver-etcd-client.crt \
  --key=/etc/kubernetes/pki/apiserver-etcd-client.key \
  get /registry/secrets/team-blue/database-password \
  > /opt/labs/etcd-secrets
```

- Note : As we are on controlplane01, the option `--endpoints=https://127.0.0.1:2379` can be omitted.

We get :

```
$ cat /opt/labs/etcd-secrets 
/registry/secrets/team-blue/database-password
k8s


v1Secret�
�
database-password�	team-blue"*$3f3ee946-9986-48eb-b4ab-1cfc841d80302̵��b�
0kubectl.kubernetes.io/last-applied-configuration�{"kind":"Secret","apiVersion":"v1","metadata":{"name":"database-password","namespace":"team-blue","creationTimestamp":null},"data":{"password":"U3VwZXJTZWNyZXQxMjM="}}
��
kubectl-createUpdate�v̵��FieldsV1:�
�{"f:data":{".":{},"f:password":{}},"f:metadata":{"f:annotations":{".":{},"f:kubectl.kubernetes.io/last-applied-configuration":{}}},"f:type":{}}B�
passwordSuperSecret123�Opaque�"
```

✅ **Result:** The raw key and value stored in etcd, in binary format, are now saved in `/opt/labs/etcd-secrets`.

---

## 🧪 Step 2 - Extract and decode the password

We can see the encoded secret in :

```
"data":{"password":"U3VwZXJTZWNyZXQxMjM="}
```

As the secret is base64 encoded, we decode it from `/opt/labs/etcd-secrets` ():

```
$ echo "U3VwZXJTZWNyZXQxMjM=" | base64 -d
SuperSecret123
```

And we can see it also at the end, between `password` and `�Opaque�` :

```
passwordSuperSecret123�Opaque�"
```

We could get the secret like this, but it is not the purpose of this lab :

```
$ k get secret database-password -n team-blue -o jsonpath='{.data.password}' | base64 -d
SuperSecret123
```

We save it :

```
$ echo SuperSecret123 > /opt/labs/database-password
```


✅ **Result:** The decoded password is saved in plain text under `/opt/labs/database-password`.

---

## 🧪 Step 3 - Encrypting Secrets and ConfigMaps at rest

### ⚙️ Configuring Encryption at Rest

Search for **data at rest** in kubernetes documentation and go to the *Encrypt your data* section :
- https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/#encrypting-your-data

As you saw, by default, Secrets and ConfigMaps are stored in plain text in etcd. To encrypt them:

**1.** Generate a 32-byte random key and encode it with **base64** :

```
$ head -c 32 /dev/urandom | base64
GdeXt1oJS5iedd3N8YjPjkF8jDLD7Vi6x4+e5MmDzBA=
```

**2.** Create the encryption config file at `/etc/kubernetes/enc/enc-config.yaml`:

```yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
      - secrets
      - configmaps
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: GdeXt1oJS5iedd3N8YjPjkF8jDLD7Vi6x4+e5MmDzBA= # the <base64-encoded-32-byte-key>
      - identity: {}
```

📝 **Explanation:**

* `resources`: Specifies the types of resources to encrypt (Secrets and ConfigMaps).
* `providers`: Defines the encryption providers in priority order :
  * `aescbc`: Encrypts the data using the AES-CBC algorithm. It requires a 32-byte key (base64-encoded).
  * `identity`: Acts as a *fallback* to keep data unencrypted. It's useful during rotation.

**3.** Configure the API server with option `--encryption-provider-config` and *volumeMounts* and *volumes*:

We edit `/etc/kubernetes/manifests/kube-apiserver.yaml` :

```yaml
...
spec:
  containers:
  - command:
    - kube-apiserver
    - --encryption-provider-config=/etc/kubernetes/enc/enc-config.yaml # ADD
    ...
   ...
    volumeMounts:
    ...
    - mountPath: /etc/kubernetes/enc # ADD
      name: encrypt                  # ADD
      readOnly: true                 # ADD
  ...
  volumes:
  ...
  - hostPath:                    # ADD
      path: /etc/kubernetes/enc  # ADD
      type: DirectoryOrCreate    # ADD
    name: encrypt                # ADD
...
```

📝 Note: This only affects newly created or updated resources. New *Secrets* and *ConfigMaps* will be encrypted .... but not the old ones !

**4.** 🔄 Rewrite existing Secrets to be encrypted

It's often not enough to make sure that new objects get encrypted: you also want that encryption to apply to the objects that are already stored.

Run this as an administrator that can read and write all *Secrets* : 

```
$ kubectl get secrets --all-namespaces -o json | kubectl replace -f -
secret/bootstrap-token-6v6f1l replaced
secret/bootstrap-token-g9h3gn replaced
secret/bootstrap-token-hy44ng replaced
secret/bootstrap-token-sgpfo3 replaced
secret/cilium-ca replaced
secret/hubble-relay-client-certs replaced
secret/hubble-server-certs replaced
secret/kubeadm-certs replaced
secret/sh.helm.release.v1.cilium.v1 replaced
secret/sh.helm.release.v1.cilium.v2 replaced
secret/database-password replaced
```

And for the *ConfiMaps* :

```
$ kubectl get configmaps --all-namespaces -o json | kubectl replace -f -
configmap/kube-root-ca.crt replaced
configmap/kube-root-ca.crt replaced
configmap/spire-agent replaced
configmap/spire-bundle replaced
configmap/spire-server replaced
configmap/kube-root-ca.crt replaced
configmap/kube-root-ca.crt replaced
configmap/cluster-info replaced
configmap/kube-root-ca.crt replaced
configmap/cilium-config replaced
configmap/cilium-envoy-config replaced
configmap/coredns replaced
configmap/extension-apiserver-authentication replaced
configmap/hubble-relay-config replaced
configmap/kube-apiserver-legacy-service-account-token-tracking replaced
configmap/kube-proxy replaced
configmap/kube-root-ca.crt replaced
configmap/kubeadm-config replaced
configmap/kubelet-config replaced
configmap/kube-root-ca.crt replaced
```

## ✅ Verification

* Confirm new etcd entries are now encrypted by re-checking the raw etcd data:

```
$ sudo ETCDCTL_API=3 etcdctl \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/apiserver-etcd-client.crt \
  --key=/etc/kubernetes/pki/apiserver-etcd-client.key \
  get /registry/secrets/team-blue/database-password | hexdump -C

00000000  2f 72 65 67 69 73 74 72  79 2f 73 65 63 72 65 74  |/registry/secret|
00000010  73 2f 74 65 61 6d 2d 62  6c 75 65 2f 64 61 74 61  |s/team-blue/data|
00000020  62 61 73 65 2d 70 61 73  73 77 6f 72 64 0a 6b 38  |base-password.k8|
00000030  73 3a 65 6e 63 3a 61 65  73 63 62 63 3a 76 31 3a  |s:enc:aescbc:v1:|
00000040  6b 65 79 31 3a 86 b0 4c  90 9b 4e e5 f7 58 2f 93  |key1:..L..N..X/.|
00000050  6e 2a 8a f1 db 8f 6d 5f  91 de be 51 67 1e bc 09  |n*....m_...Qg...|
...
```

We can see `k8s:enc:aescbc` which proves that the *Secret* is encrypted.

Let's try with a new ConfiMap :

```
$ k -n team-blue create configmap my-config --from-literal=url=https://www.google.com
configmap/my-config created
```

And we check in etcd :

```
$ sudo ETCDCTL_API=3 etcdctl \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/apiserver-etcd-client.crt \
  --key=/etc/kubernetes/pki/apiserver-etcd-client.key \
  get /registry/configmaps/team-blue/my-config | hexdump -C

00000000  2f 72 65 67 69 73 74 72  79 2f 63 6f 6e 66 69 67  |/registry/config|
00000010  6d 61 70 73 2f 74 65 61  6d 2d 62 6c 75 65 2f 6d  |maps/team-blue/m|
00000020  79 2d 63 6f 6e 66 69 67  0a 6b 38 73 3a 65 6e 63  |y-config.k8s:enc|
00000030  3a 61 65 73 63 62 63 3a  76 31 3a 6b 65 79 31 3a  |:aescbc:v1:key1:|
00000040  50 2f d1 87 7f 77 e5 ef  71 81 6c 23 ff e4 44 21  |P/...w..q.l#..D!|
00000050  18 6e 91 5a 50 51 67 bd  c1 58 6d 11 02 ff ee 22  |.n.ZPQg..Xm...."|
00000060  85 aa 4c 9f e6 f1 85 1a  ac f1 e6 ac 78 a0 7e f6  |..L.........x.~.|
00000070  a2 0b 78 37 97 19 17 74  3e 0b 8a 8b ce 2f c9 b4  |..x7...t>..../..|
...
```

We can see `k8s:enc:aescbc` which proves that the *ConfigMap* is encrypted.


## 🧹 Reset or keep it?

You can leave the encryption enabled or run `reset.sh` to restore original config and etcd data. Your choice 😄

---

🔚 **End of Lab**
