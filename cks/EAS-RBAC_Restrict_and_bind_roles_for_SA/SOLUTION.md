## Solution: Restrict and Bind Roles for a Service Account

### 🎯 Goal
Correct an overly permissive Role and assign a new Role with specific permissions to a ServiceAccount.

---

Let's check what we have :

```
$ k -n observability get all
NAME                 READY   STATUS    RESTARTS   AGE
pod/node-inspector   1/1     Running   0          38s

$ k -n observability describe pod/node-inspector 
...
Service Account:  sa-inspect
...

$ k -n observability get rolebindings -o wide
NAME               ROLE                    AGE     USERS   GROUPS   SERVICEACCOUNTS
bind-full-access   Role/full-access-role   6m56s                    observability/sa-inspect
```

So the ServiceAccount `sa-inspect` is bound to the Role `full-access-role` via the RoleBinding `bind-full-access`.

Let's check the role `full-access-role` (which is scoped to the namespace `observability`) :

```
$ k -n observability describe role full-access-role 
Name:         full-access-role
Labels:       <none>
Annotations:  <none>
PolicyRule:
  Resources    Non-Resource URLs  Resource Names  Verbs
  ---------    -----------------  --------------  -----
  deployments  []                 []              [*]
  pods         []                 []              [*]
  services     []                 []              [*]
```

We can test :

```
$ k auth can-i delete pod -n observability --as system:serviceaccount:observability:sa-inspect
yes

$ k auth can-i delete svc -n observability --as system:serviceaccount:observability:sa-inspect
yes

$ k auth can-i delete deploy -n observability --as system:serviceaccount:observability:sa-inspect
yes

```

We can edit existing Role `full-access-role` and replace its definition with the following:


```
$ k -n observability edit role full-access-role
```

```yaml
...
rules:
- apiGroups:
  - apps
  resources:
  - deployments
  verbs:
  - get
- apiGroups:
  - ""
  resources:
  - pods
  verbs:
  - get
```
This limits access to only `get` on pods and deployments.

```
$ k auth can-i delete pod -n observability --as system:serviceaccount:observability:sa-inspect
no

$ k auth can-i get pod -n observability --as system:serviceaccount:observability:sa-inspect
yes

$ k auth can-i delete deploy -n observability --as system:serviceaccount:observability:sa-inspect
no

$ k auth can-i get deploy -n observability --as system:serviceaccount:observability:sa-inspect
yes
```

### Create Role `role-statefulset-update`

```
$ k create role role-statefulset-update -n observability --resource sts --verb update  --dry-run=client -o yaml > role-statefulset-update.yaml

```

We can see `role-statefulset-update.yaml` :


```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  creationTimestamp: null
  name: role-statefulset-update
  namespace: observability
rules:
- apiGroups:
  - apps
  resources:
  - statefulsets
  verbs:
  - update
```

Apply it with:

```
kubectl apply -f role-statefulset-update.yaml
role.rbac.authorization.k8s.io/role-statefulset-update created
```

### Bind Role to ServiceAccount

```
$ k -n observability create rolebinding bind-role-statefulset-update -n observability --role role-statefulset-update --serviceaccount observability:sa-inspect -o yaml --dry-run=client > rolebinding-statefulset.yaml 
```

The file `rolebinding-statefulset.yaml` :

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  creationTimestamp: null
  name: bind-role-statefulset-update
  namespace: observability
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: role-statefulset-update
subjects:
- kind: ServiceAccount
  name: sa-inspect
  namespace: observability
```

Apply it with:
```bash
$ kubectl apply -f rolebinding-statefulset.yaml
rolebinding.rbac.authorization.k8s.io/bind-role-statefulset-update created
```

So now, we have :

```
$ k -n observability get rolebinding -o wide
NAME                           ROLE                           AGE    USERS   GROUPS   SERVICEACCOUNTS
bind-full-access               Role/full-access-role          52m                     observability/sa-inspect
bind-role-statefulset-update   Role/role-statefulset-update   4m4s                    observability/sa-inspect
```


### 🧪 Test Permissions

```
$ kubectl auth can-i --as=system:serviceaccount:observability:sa-inspect update statefulsets -n observability
Yes

$ kubectl auth can-i --as=system:serviceaccount:observability:sa-inspect get pods -n observability
Yes

$ kubectl auth can-i --as=system:serviceaccount:observability:sa-inspect list deployments -n observability
No
```

---

### 📚 Reference
- https://kubernetes.io/docs/reference/access-authn-authz/rbac/

