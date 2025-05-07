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

We get :

```
$ cat /opt/labs/etcd-secrets 
/registry/secrets/team-blue/database-password
k8s


v1Secret�
�
database-password�	team-blue"*$3b2cce97-df3c-4179-98b2-b77f03788b0f2�����a
kubectl-createUpdate�v����FieldsV1:-
+{"f:data":{".":{},"f:pass":{}},"f:type":{}}B
passU3VwZXJTZWNyZXQxMjM=�Opaque�"
```


✅ **Result:** The raw key and value stored in etcd, in binary format, are now saved in `/opt/labs/etcd-secrets`.

---

## 🧪 Step 2 - Extract and decode the password


As the secret is base64 encoded, we decode it from `/opt/labs/etcd-secrets` (at the end, between `pass` and `�Opaque�`"):

```
$ echo "U3VwZXJTZWNyZXQxMjM=" | base64 -d
SuperSecret123
```

We could get the secret like this, but it is not the prupose of this lab :

```
$ k get secret database-password -n team-blue -o jsonpath='{.data.pass}' | base64 -d | base64 -d
SuperSecret123
```

Note: the genuine secret is en encoded secret (the app that uses it can decodes it) and as the secret creation encode it again, we have to decode it twice.

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

**1.** Generate a 32-byte random key and base64 encode it :

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

```bash
sudo ETCDCTL_API=3 etcdctl ... get /registry/secrets/...  | hexdump -C
```
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
00000060  14 3b f4 54 15 cd 0e 28  0c f5 e8 fa ff ea e6 e6  |.;.T...(........|
00000070  c5 59 14 12 e2 41 7e a9  6f ec 2b 51 0f 04 5f fe  |.Y...A~.o.+Q.._.|
00000080  e5 20 28 e9 0f 33 c2 8f  07 90 01 24 ce 70 d8 5c  |. (..3.....$.p.\|
00000090  1f 51 72 e2 fd de 06 83  02 5d 11 a9 54 e9 05 8f  |.Qr......]..T...|
000000a0  e3 37 bf 50 9f 66 ef b5  10 96 f1 f2 5a c8 d3 28  |.7.P.f......Z..(|
000000b0  0c d0 fa fd 2d 1d 1b fc  7b 4e c4 fe 4d 0e a5 c0  |....-...{N..M...|
000000c0  a3 29 b2 8b 16 e2 13 39  bf 22 46 ed e6 35 91 4c  |.).....9."F..5.L|
000000d0  0e 3a a6 14 d8 c9 18 96  ef 21 8e 53 ea 3d a3 a2  |.:.......!.S.=..|
000000e0  67 f7 f7 e4 03 61 94 f5  8e 14 69 64 a2 ef 3c 5f  |g....a....id..<_|
000000f0  96 76 fc 60 66 00 e7 76  a9 07 ca 4a fe 1f 36 43  |.v.`f..v...J..6C|
00000100  97 60 fa f1 93 04 58 54  66 f4 a8 16 fa 0b cb 25  |.`....XTf......%|
00000110  f7 f7 41 29 a0 ae 3c e5  93 cd c6 5b 00 a9 80 7f  |..A)..<....[....|
00000120  4f 6c 4e a3 d4 f1 e8 67  df 29 80 3a 65 b6 2c 2e  |OlN....g.).:e.,.|
00000130  b5 f1 07 e2 be 11 e1 d4  c0 3a 36 f9 91 71 db af  |.........:6..q..|
00000140  c4 66 50 cd 29 fd bd c3  b4 65 00 08 bc 80 c5 54  |.fP.)....e.....T|
00000150  2f d3 d3 86 f0 0a                                 |/.....|
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
00000080  74 62 a1 07 83 b6 89 0e  77 0e 12 d9 05 f1 6b 31  |tb......w.....k1|
00000090  e7 42 4a e3 08 b6 33 83  20 9f 6f d5 d7 e0 58 22  |.BJ...3. .o...X"|
000000a0  bf b2 a4 70 2a c9 ff d2  4e ed 52 58 71 3c 41 1a  |...p*...N.RXq<A.|
000000b0  b5 dc a6 30 1b 7c 1d 1e  b5 8a 58 24 3a b0 c5 c8  |...0.|....X$:...|
000000c0  8f 71 49 36 3f 65 16 d9  21 c5 11 f4 ad 65 f3 12  |.qI6?e..!....e..|
000000d0  d7 0b 72 80 31 a1 cd 15  c3 b8 79 89 c6 4b 12 17  |..r.1.....y..K..|
000000e0  36 74 67 e0 04 1c ac 44  f7 83 14 7b 03 32 99 b5  |6tg....D...{.2..|
000000f0  7d 65 fd 51 a5 62 93 cd  e0 83 19 df c0 5e 59 83  |}e.Q.b.......^Y.|
00000100  3a c4 5a 9d f9 dd b8 34  9b ad ce 7e 7b a4 35 aa  |:.Z....4...~{.5.|
00000110  2d f0 74 c9 ba 6c 37 63  66 c1 7a 12 d1 f6 0a 6a  |-.t..l7cf.z....j|
00000120  86 dc e8 3b ea a2 7a c8  08 2d 04 85 8e 96 72 b7  |...;..z..-....r.|
00000130  36 62 31 58 1a 00 ed 00  a6 c1 33 e1 31 36 77 8c  |6b1X......3.16w.|
00000140  0a                                                |.|
00000141
```

We can see `k8s:enc:aescbc` which proves that the *ConfigMap* is encrypted.


## 🧹 Reset or keep it?

You can leave the encryption enabled or run `reset.sh` to restore original config and etcd data. Your choice 😄

---

🔚 **End of Lab**
