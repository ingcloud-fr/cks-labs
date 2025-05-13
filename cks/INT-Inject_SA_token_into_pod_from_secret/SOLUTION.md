## Solution: Inject a ServiceAccount token into a Pod from a Secret

This lab demonstrates how to create a short-lived ServiceAccount token and securely inject it into a Pod using two different methods: via environment variable and via a projected volume.

---

### ✅ Step-by-step solution

#### 1. Create the ServiceAccount

```
$ kubectl create serviceaccount custom-bot -n team-blue
serviceaccount/custom-bot created
```

#### 2. Create a 20-minute token and save it to a file

```
$ kubectl -n team-blue create token custom-bot --duration=20m > token.txt
```

#### 3. Create a Secret from the token file

```
$ kubectl -n team-blue create secret generic custom-bot-token --from-file=token=token.txt 
secret/custom-bot-token created
```

> 📦 The key must be named `token` because that will be referenced later in the Pod definition.

#### 4. Give the ServiceAccount minimal read access

Let's have a look on the `view` ClusterRole :

```
$ k describe clusterrole view 
Name:         view
Labels:       kubernetes.io/bootstrapping=rbac-defaults
              rbac.authorization.k8s.io/aggregate-to-edit=true
Annotations:  rbac.authorization.kubernetes.io/autoupdate: true
PolicyRule:
  Resources                                    Non-Resource URLs  Resource Names  Verbs
  ---------                                    -----------------  --------------  -----
  bindings                                     []                 []              [get list watch]
  configmaps                                   []                 []              [get list watch]
  endpoints                                    []                 []              [get list watch]
  events                                       []                 []              [get list watch]
  limitranges                                  []                 []              [get list watch]
  ...
```
By default, a ServiceAccount has no permissions. Bind it to the `view` clusterrole:

```
$ k -n team-blue create rolebinding rb-custom-bot --clusterrole view --serviceaccount team-blue:custom-bot
rolebinding.rbac.authorization.k8s.io/rb-custom-bot created
```

> 🔐 You can use `clusterrolebinding` if you want the SA to access resources across all namespaces.

---

### 🔧 Option 1: Inject token using env variable (valueFrom)

Search for **secret pod** in documentation, and select **Distribute Credentials Securely Using Secrets**
- https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/#define-container-environment-variables-using-secret-data

Create a Pod :

```
$ k -n team-blue run pod-test --image curlimages/curl --dry-run=client -oyaml --command -- sleep 3600 > pod-test.yaml
```

Edit it and add :

```yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod-test
  name: pod-test
  namespace: team-blue
spec:
  containers:
  - command:
    - sleep
    - "3600"
    image: curlimages/curl
    name: pod-test
    resources: {}
    env:                          # ADD
    - name: TOKEN_API             # ADD
      valueFrom:                  # ADD
        secretKeyRef:             # ADD
          name: custom-bot-token  # ADD
          key: token              # ADD
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

Apply it:

```
$ k apply -f pod-test.yaml 
pod/pod-test created
```

Then exec inside:

```
$ $ k -n team-blue exec -it pod/pod-test -- sh
~ $ echo $TOKEN_API
eyJhbGciOiJSUzI1NiIsImtpZCI6Ild6dk12alJHZk9qVWpCVnZOYnEzalpxM1NEYjZ3Mmw1STMtcVExV0Fud28ifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiXSwiZXhwIjoxNzQ3MTQ4MzIzLCJpYXQiOjE3NDcxNDcxMjMsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwianRpIjoiN2RmNjkwZjktMzRkYi00Y2FjLThjNTUtNTVkZjU4YjQwOGFiIiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJ0ZWFtLWJsdWUiLCJzZXJ2aWNlYWNjb3VudCI6eyJuYW1lIjoiY3VzdG9tLWJvdCIsInVpZCI6IjQzMGQ3YzZkLWFjNmQtNDlmMi1hNzQ0LTQ3MDZlMzZhZWU1YiJ9fSwibmJmIjoxNzQ3MTQ3MTIzLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6dGVhbS1ibHVlOmN1c3RvbS1ib3QifQ.GjTOeZDMYI1yfmtZSNGErEXBB4H5amjUjcxUWGFn1Du95KgBSGEXbb9GQPvtlOK9GyagdgmcbD4CWGUJuW7is2zB7iSgsGkZ4AUmzNntXhcqGH1Va60vnf7Fvfrrei4IC0rX1tD6uXKGCLRtxy1l5kjGQyiKR_lMEefOArm4fpQGIRyc6F72dTDUK8IPK0hL_J0wlJhDbtv597K8-025lj4olkIOz2RMtnQCyxGyVf1B_qKNz8iYIL3bp5mMIwUAkvlDVgiTewWdkV_u6rrg0rMbCbCHQ5OP2MAc1hnNdCN9atUvBvXHkdfkMOCkMlVEQWbjhf_Lxij9jN8BwlFjfA

~ $ curl -sSk -H "Authorization: Bearer $TOKEN_API" https://kubernetes.default.svc/api
{
  "kind": "APIVersions",
  "versions": [
    "v1"
  ],
  "serverAddressByClientCIDRs": [
    {
      "clientCIDR": "0.0.0.0/0",
      "serverAddress": "192.168.1.200:6443"
    }
  ]
}~ $ 

~ $ exit
```


### 🗂️ Option 2: Inject token using projected volume

Create a Pod with the token mounted as a projected volume :

```
$ k -n team-blue run pod-test2 --image curlimages/curl --dry-run=client -oyaml --command -- sleep 3600 > pod-test2.yaml
```

Search for **projected volume** in documentation : https://kubernetes.io/docs/concepts/storage/projected-volumes/

Edit pod-test2.yaml and add :

```yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod-test2
  name: pod-test2
  namespace: team-blue
spec:
  containers:
  - command:
    - sleep
    - "3600"
    image: curlimages/curl
    name: pod-test2
    resources: {}
    volumeMounts:                    # ADD
    - name: projected-secret         # ADD 
      mountPath: "/projected-volume" # ADD
      readOnly: true                 # ADD 
  dnsPolicy: ClusterFirst
  restartPolicy: Always
  volumes:                       # ADD
  - name: projected-secret       # ADD
    projected:                   # ADD
      sources:                   # ADD
      - secret:                  # ADD
          name: custom-bot-token # ADD
          items:                 # ADD
            - key: token         # ADD - the key od the Secret
              path: token-api    # ADD - The path after the mountPath
status: {}
```

Apply it:

```
$ k apply -f pod-test2.yaml 
pod/pod-test2 created

```

Then exec inside:

```
$ k -n team-blue exec -it pod/pod-test2 -- sh
~ $ cat /projected-volume/token-api
eyJhbGciOiJSUzI1NiIsImtpZCI6Ild6dk12alJHZk9qVWpCVnZOYnEzalpxM1NEYjZ3Mmw1STMtcVExV0Fud28ifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiXSwiZXhwIjoxNzQ3MTQ4MzIzLCJpYXQiOjE3NDcxNDcxMjMsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwianRpIjoiN2RmNjkwZjktMzRkYi00Y2FjLThjNTUtNTVkZjU4YjQwOGFiIiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJ0ZWFtLWJsdWUiLCJzZXJ2aWNlYWNjb3VudCI6eyJuYW1lIjoiY3VzdG9tLWJvdCIsInVpZCI6IjQzMGQ3YzZkLWFjNmQtNDlmMi1hNzQ0LTQ3MDZlMzZhZWU1YiJ9fSwibmJmIjoxNzQ3MTQ3MTIzLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6dGVhbS1ibHVlOmN1c3RvbS1ib3QifQ.GjTOeZDMYI1yfmtZSNGErEXBB4H5amjUjcxUWGFn1Du95KgBSGEXbb9GQPvtlOK9GyagdgmcbD4CWGUJuW7is2zB7iSgsGkZ4AUmzNntXhcqGH1Va60vnf7Fvfrrei4IC0rX1tD6uXKGCLRtxy1l5kjGQyiKR_lMEefOArm4fpQGIRyc6F72dTDUK8IPK0hL_J0wlJhDbtv597K8-025lj4olkIOz2RMtnQCyxGyVf1B_qKNz8iYIL3bp5mMIwUAkvlDVgiTewWdkV_u6rrg0rMbCbCHQ5OP2MAc1hnNdCN9atUvBvXHkdfkMOCkMlVEQWbjhf_Lxij9jN8BwlFjfA~ $ 
~ $ 
~ $ TOKEN_API=$(cat /projected-volume/token-api)
~ $ curl -sSk -H "Authorization: Bearer $TOKEN_API" https://kubernetes.default.svc/api
{
  "kind": "APIVersions",
  "versions": [
    "v1"
  ],
  "serverAddressByClientCIDRs": [
    {
      "clientCIDR": "0.0.0.0/0",
      "serverAddress": "192.168.1.200:6443"
    }
  ]
}~ $ exit

```

### 🧠 Takeaways

* This lab helps visualize two techniques for injecting tokens securely.
* In production, mounting secrets as projected volumes is preferred over env vars for sensitive data.
* You’ve learned to manually create a short-lived token and control how it’s consumed.
* A ServiceAccount has **no access** by default — you must bind it to roles via RBAC.

---

### 🧰 Debugging & Common Errors

#### ❌ `system:anonymous` / 403 Forbidden

* Cause: Token not injected or used
* Fix: Use `Bearer $TOKEN_API` or `Bearer $TOKEN`, not the wrong variable name

#### ❌ `401 Unauthorized`

* Cause: Token expired (**you took too much time !**), malformed, or not recognized by API
* Fix:

  * Regenerate with `kubectl create token ...`
  * Recreate the Secret with updated token
  * Check expiration with `jq .exp`

#### 🔒 Token is valid but still 401?

* Check if SA has permissions:

```bash
$ kubectl auth can-i get pods --as=system:serviceaccount:team-blue:custom-bot -n team-blue
yes
```

* Check if token content matches the expected `sub` claim:

```bash
echo $TOKEN_API | cut -d. -f2 | base64 -d
{"aud":["https://kubernetes.default.svc.cluster.local"],"exp":1747148323,"iat":1747147123,"iss":"https://kubernetes.default.svc.cluster.local","jti":"7df690f9-34db-4cac-8c55-55df58b408ab","kubernetes.io":{"namespace":"team-blue","serviceaccount":{"name":"custom-bot","uid":"430d7c6d-ac6d-49f2-a744-4706e36aee5b"}},"nbf":1747147123,"sub":"system:serviceaccount:team-blue:custom-bot"base64: truncated input
~ $ 

```

#### ✅ Final test locally with a temporary kubeconfig

```bash
export TOKEN=$(cat token.txt)
export CACERT=$(kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
export SERVER=$(kubectl config view --raw -o jsonpath='{.clusters[0].cluster.server}')

cat <<EOF > tmp-kubeconfig.yaml
apiVersion: v1
kind: Config
clusters:
- name: test
  cluster:
    certificate-authority-data: $CACERT
    server: $SERVER
users:
- name: custom-bot
  user:
    token: $TOKEN
contexts:
- name: custom-bot@test
  context:
    cluster: test
    user: custom-bot
current-context: custom-bot@test
EOF
```

And use it :

```
$ KUBECONFIG=tmp-kubeconfig.yaml kubectl get pods -n team-blue
NAME        READY   STATUS    RESTARTS   AGE
pod-test    1/1     Running   0          24m
pod-test2   1/1     Running   0          15m
```

---

### 📘 References

* [https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
* [https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables)
* [https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-files-from-a-pod](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-files-from-a-pod)
* [https://kubernetes.io/docs/reference/access-authn-authz/rbac/](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
