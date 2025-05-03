## Solution: Create User Janice with Certificate and Roles

Search for **csr** in the Kubernetes documentation, at the bottom *Read Issue a Certificate for a Kubernetes API Client Using A CertificateSigningRequest* or search for **csr client** in the Kubernetes documentation to get this page :

- Doc : https://kubernetes.io/docs/tasks/tls/certificate-issue-client-csr/

In this documentation, you will find how to create the private key, create the X.509 CSR, create a Kubernetes CSR abd approve it and **get the user certificate** for the kubeconfig file.

Search for **multiple kubeconfig** in the Kubernetes documentation :

- Doc: https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/

In this documentation, you will find how to create a kubeconfig file : set-cluster, set-credentials, set-context and **use-context** to set the `current-context` in the kubeconfig file.


### 🧰 Step 1 — Generate a private key and CSR for janice


We follow : https://kubernetes.io/docs/tasks/tls/certificate-issue-client-csr/

```bash
$ openssl genrsa -out janice.key 2048
$ openssl req -new -key janice.key -out janice.csr -subj "/CN=janice/O=developer"
```

### 📄 Step 2 — Create a CertificateSigningRequest manifest


We encode the CSR using :

```
$ cat janince.csr | base64 | tr -d "\n"
LS0tLS1CRUdJTiBDRVJUSUZJQ0FURSBSRVFVRVNULS0tLS0KT...09sNGUrMkNucGV6UzB5Yko0ZDJheApIZz09Ci0tLS0tRU5EIENFUlRJRklDQVRFIFJFUVVFU1QtLS0tLQo=
```

Create a file `janice-csr.yaml` with the encoded CSR (field `request:`)

```yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: janice-csr
spec:
  request: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURSBSRVFVRVNULS0tLS0KT...09sNGUrMkNucGV6UzB5Yko0ZDJheApIZz09Ci0tLS0tRU5EIENFUlRJRklDQVRFIFJFUVVFU1QtLS0tLQo=
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400
  usages:
    - client auth
```
Apply it:

```
$ k apply -f janice-csr.yaml 
certificatesigningrequest.certificates.k8s.io/janice-csr created
```

We can see :

```
$ k get csr
NAME         AGE   SIGNERNAME                            REQUESTOR          REQUESTEDDURATION   CONDITION
janice-csr   53s   kubernetes.io/kube-apiserver-client   kubernetes-admin   24h                 Pending
```
Approve it:

```
$ k certificate approve janice-csr
certificatesigningrequest.certificates.k8s.io/janice-csr approved
```

Now the CSR is approved :

```
$ k get csr
NAME         AGE   SIGNERNAME                            REQUESTOR          REQUESTEDDURATION   CONDITION
janice-csr   88s   kubernetes.io/kube-apiserver-client   kubernetes-admin   24h                 Approved,Issued

```

Get janice's certificate (ie the signed CSR signed by Kubernetes CA) and decode it :
```
$ k get csr janice-csr -o jsonpath='{.status.certificate}' | base64 -d > janice.crt
```


### 🔑 Step 3 — Create a kubeconfig for janice

Search for kubeconfig on Kubernetes docs : *Configure Access to Multiple Clusters*
https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/

The structure of a kubeconfig :

```bash
[Cluster] # with k config set-cluster
  ➜  Server URL
  ➜  CA cert to trust API Server (usualy /etc/kubernetes/pki/ca.crt)

[User] # with k config set-credentials
  ➜  Client cert + Client key to authenticate

[Context] # with k config set-context
  ➜  Binds [User] and [Cluster]
```

We can use the examples of the help :

```
$ k config set-cluster --help
Set a cluster entry in kubeconfig.

 Specifying a name that already exists will merge new fields on top of existing values for those fields.

Examples:
  # Set only the server field on the e2e cluster entry without touching other values
  kubectl config set-cluster e2e --server=https://1.2.3.4
  
  # Embed certificate authority data for the e2e cluster entry
  kubectl config set-cluster e2e --embed-certs --certificate-authority=~/.kube/e2e/kubernetes.ca.crt
...
```

```
$ k config set-credentials --help
Set a user entry in kubeconfig.

 Specifying a name that already exists will merge new fields on top of existing values.

        Client-certificate flags:
        --client-certificate=certfile --client-key=keyfile
        
        Bearer token flags:
        --token=bearer_token
        
        Basic auth flags:
        --username=basic_user --password=basic_password
        
 Bearer token and basic auth are mutually exclusive.

Examples:
  # Set only the "client-key" field on the "cluster-admin"
  # entry, without touching other values
  kubectl config set-credentials cluster-admin --client-key=~/.kube/admin.key

  ...
  
  # Embed client certificate data in the "cluster-admin" entry
  kubectl config set-credentials cluster-admin --client-certificate=~/.kube/admin.crt --embed-certs=true
...
```

```
$ k config set-context --help
...

Examples:
  # Set the user field on the gce context entry without touching other values
  kubectl config set-context gce --user=cluster-admin
...
```

We use the certificat and keys embed in the kube-config file using `--embed-certs=true` (unless it's the path)

```
$ kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/pki/ca.crt \
  --embed-certs=true \
  --server=https://k8s-controlplane01:6443 \
  --kubeconfig=janice.kubeconfig
Cluster "kubernetes" set.
```

```
$ kubectl config set-credentials janice \
  --client-certificate=janice.crt \
  --client-key=janice.key \
  --embed-certs=true \
  --kubeconfig=janice.kubeconfig
User "janice" set.
```

```
$ kubectl config set-context janice-context \
  --cluster=kubernetes \
  --user=janice \
  --kubeconfig=janice.kubeconfig
Context "janice-context" created.
```

If we check the context when using kubeconfig janice.kubeconfig, we can see it's not set :

```
$ kubectl config current-context --kubeconfig janice.kubeconfig 
error: current-context is not set
```

We can see it also in the kubeconfig file :

```
$ cat janice.kubeconfig | grep current-context
current-context: ""
```

Now, we can set the context :

```
$ kubectl config use-context janice-context --kubeconfig=janice.kubeconfig
Switched to context "janice-context".
```

We can see it in `janice.kubeconfig` :

```
$ cat janice.kubeconfig | grep current-context
current-context: janice-context
```

- Note: When kubectl can't find a correct current-context or cluster, it tries to talk to the default server → http://localhost:8080 → this obviously fails :

```
"Unhandled Error" err="couldn't get current server API group list: Get \"http://localhost:8080/api?timeout=32s\": dial tcp 127.0.0.1:8080: connect: connection refused"
```


### 🔐 Step 4 — Create Role and RoleBinding
#### Role

We create the role `pod-reader` :

```
$ k create role pod-reader -n team-green --resource=pods  --verb list,get,watch -o yaml --dry-run=client > role-pod-reader.yaml
```

The file `role-pod-reader.yaml` : 

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  creationTimestamp: null
  name: pod-reader
  namespace: team-green
rules:
- apiGroups:
  - ""
  resources:
  - pods
  verbs:
  - list
  - get
  - watch
```

```
$ k apply -f role-pod-reader.yaml 
role.rbac.authorization.k8s.io/pod-reader created
```

#### RoleBinding

Now create a rolebinding with the role `pod-reader` and the user `janice` :

```
$ k create rolebinding janice-binding -n team-green --role pod-reader --user janice -oyaml --dry-run=client > janice-binding.yaml
```

The file `janice-binding.yaml` :

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  creationTimestamp: null
  name: janice-binding
  namespace: team-green
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-reader
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: janice
```

We apply it :

```
$ k apply -f janice-binding.yaml 
rolebinding.rbac.authorization.k8s.io/janice-binding created
```

### ✅ Step 5 — Test Janice's access

```
$ kubectl --kubeconfig=janice.kubeconfig get pods -n team-green
No resources found in team-green namespace.

$ kubectl --kubeconfig=janice.kubeconfig -n team-green run nginx --image nginx
Error from server (Forbidden): pods is forbidden: User "janice" cannot create resource "pods" in API group "" in the namespace "team-green"

$ kubectl --kubeconfig=janice.kubeconfig auth can-i create pods -n team-green
no

$ kubectl --kubeconfig janice-kubeconfig -n team-green auth can-i list pod
yes
```

Expected:
- ✅ get/list/watch allowed
- ❌ create/delete not allowed

---

### 🧼 Cleanup manually (optional)
```bash
kubectl delete csr janice-csr
rm janice.*
```

---

### 📚 References
- https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/
- https://kubernetes.io/docs/reference/access-authn-authz/rbac/

