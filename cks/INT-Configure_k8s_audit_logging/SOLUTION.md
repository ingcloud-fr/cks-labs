# ✅ SOLUTION — CH-ADV-Configure_k8s_audit_logging

## 🎯 Lab Objective Recap
Enable audit logging in Kubernetes and verify that sensitive operations are properly logged according to the policy.

---

## 🛠️ Step-by-step Solution

### 🔹 Step 1: Create the audit policy file

Create directories :

```
$ sudo mkdir /etc/kubernetes/audit/
$ sudo mkdir -p /var/log/kubernetes/audit/
```

Create the file `/etc/kubernetes/audit/prod-policy.yaml` with the following content:

```yaml
apiVersion: audit.k8s.io/v1
kind: Policy
omitStages:
  - "RequestReceived"

rules:
  # 🟢 Log pod creation and deletion (any namespace)
  - level: RequestResponse
    verbs: ["create", "delete"]
    resources:
      - group: ""
        resources: ["pods"]

  # 📄 Log all access to pod logs (any verb)
  - level: Metadata
    resources:
      - group: ""
        resources: ["pods/log"]

  # 🔐 Log modification and deletion of secrets outside kube-system
  - level: Metadata
    verbs: ["delete","update","patch"]
    resources:
      - group: ""
        resources: ["secrets"]

  # 🧼 Log deletion of configmaps in kube-system
  - level: Request
    verbs: ["delete"]
    resources:
      - group: ""
        resources: ["configmaps"]
    namespaces:
      - "kube-system"

  # 🛠️ Log modification (update) of deployments in any namespace
  - level: Request
    verbs: ["update"]
    resources:
      - group: "apps"
        resources: ["deployments"]

  # 🚫 Do not log access to non-resource URLs (e.g. /api, /version)
  - level: None
    nonResourceURLs:
      - "/api*"

```

#### 🔄 Update vs Patch in Audit Logs

- **Update** operations replace the entire resource object with a new one. They are typically triggered by commands like `kubectl apply`, which re-applies the full manifest.
- **Patch** operations modify only parts of the resource (a subset of fields). These are common in `kubectl patch` or when `kubectl edit` results in partial changes.

To accurately capture changes to sensitive objects (e.g., Secrets), audit policies should include **both `update` and `patch` verbs** to cover all possible modification methods.


### 🔹 Step 2: Configure the API server to use this policy

A good practise is to backup your kube-apiserver.yaml :

```
$ sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml /tmp
```

Modify the kube-apiserver manifest:

```bash
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml
```

Add or modify the following flags, volumeMount and volumes and the:

```yaml
- --audit-policy-file=/etc/kubernetes/audit/prod-policy.yaml
- --audit-log-path=/var/log/kubernetes/audit/audit-prod.log
- --audit-log-maxage=30
- --audit-log-maxbackup=2
....
        volumeMounts:
        - mountPath: /etc/kubernetes/audit
          name: audit-policies
          readOnly: true
        - mountPath: /var/log/kubernetes/audit
          name: audit-logs
...
  volumes:
    - name: audit-policies
      hostPath:
        path: /etc/kubernetes/audit
        type: DirectoryOrCreate

    - name: audit-logs
      hostPath:
        path: /var/log/kubernetes/audit
        type: DirectoryOrCreate

```

The kubelet will automatically restart the API server when the manifest changes.

```json
$ sudo tail -f /var/log/kubernetes/audit/audit-prod.log | jq
{
  "kind": "Event",
  "apiVersion": "audit.k8s.io/v1",
  "level": "RequestResponse",
  "auditID": "d1921445-0fa3-42e4-906c-9b5d6f4858c7",
  "stage": "ResponseComplete",
  "requestURI": "/api/v1/namespaces/kube-system/pods/kube-apiserver-k8s-controlplane",
  "verb": "delete",
  "user": {
    "username": "system:node:k8s-controlplane",
    "groups": [
      "system:nodes",
      "system:authenticated"
    ],
    "extra": {
      "authentication.kubernetes.io/credential-id": [
        "X509SHA256=344d612dde021646f532e0ef88673cc04a7cbd90031cd062a814ddc57b63838b"
      ]
    }
  },
  "sourceIPs": [
    "192.168.1.200"
  ],
  "userAgent": "kubelet/v1.32.3 (linux/amd64) kubernetes/32cc146",
  "objectRef": {
    "resource": "pods",
    "namespace": "kube-system",
    "name": "kube-apiserver-k8s-controlplane",
    "apiVersion": "v1"
  },
  "responseStatus": {
    "metadata": {},
    "status": "Failure",
    "message": "Operation cannot be fulfilled on Pod \"kube-apiserver-k8s-controlplane\": the UID in the precondition (ed69f6bf-ab71-4d20-9523-b95b81dd1ed9) does not match the UID in record (e7fcf263-8a10-46dc-b064-da8cd9f0d197). The object might have been deleted and then recreated",
    "reason": "Conflict",
    "details": {
      "name": "kube-apiserver-k8s-controlplane",
      "kind": "Pod"
    },
    "code": 409
  },
  "requestObject": {
    "kind": "DeleteOptions",
    "apiVersion": "meta.k8s.io/__internal",
    "gracePeriodSeconds": 0,
    "preconditions": {
      "uid": "ed69f6bf-ab71-4d20-9523-b95b81dd1ed9"
    }
  },
  "responseObject": {
    "kind": "Status",
    "apiVersion": "v1",
    "metadata": {},
    "status": "Failure",
    "message": "Operation cannot be fulfilled on Pod \"kube-apiserver-k8s-controlplane\": the UID in the precondition (ed69f6bf-ab71-4d20-9523-b95b81dd1ed9) does not match the UID in record (e7fcf263-8a10-46dc-b064-da8cd9f0d197). The object might have been deleted and then recreated",
    "reason": "Conflict",
    "details": {
      "name": "kube-apiserver-k8s-controlplane",
      "kind": "Pod"
    },
    "code": 409
  },
  "requestReceivedTimestamp": "2025-04-16T16:55:37.142368Z",
  "stageTimestamp": "2025-04-16T16:55:37.145097Z",
  "annotations": {
    "authorization.k8s.io/decision": "allow",
    "authorization.k8s.io/reason": ""
  }
}
```


### 🔹 Step 3: Trigger test events manually

#### 🧪 Pod creation
```bash
$ k run testpod --image=nginx -n default
```

In the audit log :

```json
{
  "kind": "Event",
  "apiVersion": "audit.k8s.io/v1",
  "level": "RequestResponse",
  "auditID": "d5edea79-d84d-41d7-bcff-591e7d67f25e",
  "stage": "ResponseComplete",
  "requestURI": "/api/v1/namespaces/default/pods?fieldManager=kubectl-run",
  "verb": "create",
  "user": {
    "username": "kubernetes-admin",
    "groups": [
      "kubeadm:cluster-admins",
      "system:authenticated"
    ],
    "extra": {
      "authentication.kubernetes.io/credential-id": [
        "X509SHA256=96f6f167b921061bb17c858bdbfb75b4cba41cc73218345837fa48d1f3f68fda"
      ]
    }
  },
  "sourceIPs": [
    "192.168.1.200"
  ],
  "userAgent": "kubectl/v1.32.3 (linux/amd64) kubernetes/32cc146",
  "objectRef": {
    "resource": "pods",
    "namespace": "default",
    "name": "testpod",
    "apiVersion": "v1"
  },
...
```


#### 🧪 Pod logs access
```bash
$ k logs deploy/frontend -n team-pink
```

```json
{
  "kind": "Event",
  "apiVersion": "audit.k8s.io/v1",
  "level": "Metadata",
  "auditID": "98a5b50a-05d0-41e0-9568-ced7a292d061",
  "stage": "ResponseStarted",
  "requestURI": "/api/v1/namespaces/team-pink/pods/frontend-d8c9f8976-w5xdc/log?container=nginx",
  "verb": "get",
  "user": {
    "username": "kubernetes-admin",
    "groups": [
      "kubeadm:cluster-admins",
      "system:authenticated"
    ],
    "extra": {
      "authentication.kubernetes.io/credential-id": [
        "X509SHA256=96f6f167b921061bb17c858bdbfb75b4cba41cc73218345837fa48d1f3f68fda"
      ]
    }
  },
  "sourceIPs": [
    "192.168.1.200"
  ],
  "userAgent": "kubectl/v1.32.3 (linux/amd64) kubernetes/32cc146",
  "objectRef": {
    "resource": "pods",
    "namespace": "team-pink",
    "name": "frontend-d8c9f8976-w5xdc",
    "apiVersion": "v1",
    "subresource": "log"
  },
  "responseStatus": {
    "metadata": {},
    "code": 200
  },
....
```


#### 🧪 Secret update + delete
```
$ k create secret generic testsecret --from-literal=password=12345 -n default
$ k edit secret testsecret -n default   # We modify 1 letter in data.password
```

```json
{
  "kind": "Event",
  "apiVersion": "audit.k8s.io/v1",
  "level": "Metadata",
  "auditID": "e290c855-79cf-4f6c-bef8-6190fdc836f8",
  "stage": "ResponseComplete",
  "requestURI": "/api/v1/namespaces/default/secrets/testsecret?fieldManager=kubectl-edit&fieldValidation=Strict",
  "verb": "patch",
  "user": {
    "username": "kubernetes-admin",
    "groups": [
      "kubeadm:cluster-admins",
      "system:authenticated"
    ],
    "extra": {
      "authentication.kubernetes.io/credential-id": [
        "X509SHA256=96f6f167b921061bb17c858bdbfb75b4cba41cc73218345837fa48d1f3f68fda"
      ]
    }
  },
  "sourceIPs": [
    "192.168.1.200"
  ],
  "userAgent": "kubectl/v1.32.3 (linux/amd64) kubernetes/32cc146",
  "objectRef": {
    "resource": "secrets",
    "namespace": "default",
    "name": "testsecret",
    "apiVersion": "v1"
  },
  "responseStatus": {
    "metadata": {},
    "code": 200
  },
  "requestReceivedTimestamp": "2025-04-16T20:41:49.873854Z",
  "stageTimestamp": "2025-04-16T20:41:49.875945Z",
  "annotations": {
    "authorization.k8s.io/decision": "allow",
    "authorization.k8s.io/reason": "RBAC: allowed by ClusterRoleBinding \"kubeadm:cluster-admins\" of ClusterRole \"cluster-admin\" to Group \"kubeadm:cluster-admins\""
  }
}

```

```
$ k delete secret testsecret -n default
```

```json
{
  "kind": "Event",
  "apiVersion": "audit.k8s.io/v1",
  "level": "Metadata",
  "auditID": "141e3c04-c82b-4af2-9a88-4da064162d3e",
  "stage": "ResponseComplete",
  "requestURI": "/api/v1/namespaces/default/secrets/testsecret",
  "verb": "delete",
  "user": {
    "username": "kubernetes-admin",
    "groups": [
      "kubeadm:cluster-admins",
      "system:authenticated"
    ],
    "extra": {
      "authentication.kubernetes.io/credential-id": [
        "X509SHA256=96f6f167b921061bb17c858bdbfb75b4cba41cc73218345837fa48d1f3f68fda"
      ]
    }
  },
  "sourceIPs": [
    "192.168.1.200"
  ],
  "userAgent": "kubectl/v1.32.3 (linux/amd64) kubernetes/32cc146",
  "objectRef": {
    "resource": "secrets",
    "namespace": "default",
    "name": "testsecret",
    "apiVersion": "v1"
  },
...
```


#### 🧪 ConfigMap deletion in kube-system
```
$ k create configmap temp-cfg --from-literal=foo=bar -n kube-system
$ k delete configmap temp-cfg -n kube-system
```

```json
{
  "kind": "Event",
  "apiVersion": "audit.k8s.io/v1",
  "level": "Request",
  "auditID": "07c20769-bab5-4ead-b773-9bfdaa184b4b",
  "stage": "ResponseComplete",
  "requestURI": "/api/v1/namespaces/kube-system/configmaps/temp-cfg",
  "verb": "delete",
  "user": {
    "username": "kubernetes-admin",
    "groups": [
      "kubeadm:cluster-admins",
      "system:authenticated"
    ],
    "extra": {
      "authentication.kubernetes.io/credential-id": [
        "X509SHA256=96f6f167b921061bb17c858bdbfb75b4cba41cc73218345837fa48d1f3f68fda"
      ]
    }
  },
  "sourceIPs": [
    "192.168.1.200"
  ],
  "userAgent": "kubectl/v1.32.3 (linux/amd64) kubernetes/32cc146",
  "objectRef": {
    "resource": "configmaps",
    "namespace": "kube-system",
    "name": "temp-cfg",
    "apiVersion": "v1"
  },
  "responseStatus": {
    "metadata": {},
    "status": "Success",
    "details": {
      "name": "temp-cfg",
      "kind": "configmaps",
      "uid": "3da83c74-f7fa-4135-a5db-88c50a39a96c"
    },
    "code": 200
  },
  "requestObject": {
    "kind": "DeleteOptions",
    "apiVersion": "meta.k8s.io/__internal",
    "propagationPolicy": "Background"
  },
  "requestReceivedTimestamp": "2025-04-16T20:42:50.596951Z",
  "stageTimestamp": "2025-04-16T20:42:50.608192Z",
  "annotations": {
    "authorization.k8s.io/decision": "allow",
    "authorization.k8s.io/reason": "RBAC: allowed by ClusterRoleBinding \"kubeadm:cluster-admins\" of ClusterRole \"cluster-admin\" to Group \"kubeadm:cluster-admins\""
  }
}

```


#### 🧪 Modify deployment in team-pink
```
$ k -n team-pink scale deployment frontend --replicas 2
```

```json
{
  "kind": "Event",
  "apiVersion": "audit.k8s.io/v1",
  "level": "RequestResponse",
  "auditID": "05f3cc6a-cb8f-4436-a006-4e07a3ca5b20",
  "stage": "ResponseComplete",
  "requestURI": "/api/v1/namespaces/team-pink/pods",
  "verb": "create",
  "user": {
    "username": "system:serviceaccount:kube-system:replicaset-controller",
    "uid": "02a51454-18ec-4729-8f83-fef3a1ed9560",
    "groups": [
      "system:serviceaccounts",
      "system:serviceaccounts:kube-system",
      "system:authenticated"
    ],
    "extra": {
      "authentication.kubernetes.io/credential-id": [
        "JTI=061efc01-ecc8-47e5-a488-15a3b815dad0"
      ]
    }
  },

```


#### 🧪 Try hitting nonResource /api (should NOT be logged)

We send an non authentificated request :

```bash
$ curl -k https://localhost:6443/api --cacert /etc/kubernetes/pki/ca.crt
```
=> No log !

### 🔍 Step 4: Inspect audit log

```bash
sudo grep -E 'pod|secret|configmap|deployment' /var/log/kubernetes/audit/audit-prod.log | less
```

Check each logged entry for:
- `verb`: create / delete / get / update
- `user.username`
- `objectRef.resource`
- `objectRef.namespace`
- `responseStatus`

---

## ✅ Good Practices

- Keep audit logs on persistent storage or ship to a log collector (Fluentd, ELK, Loki, etc.)
- Use `RequestResponse` only where needed — it may leak sensitive data
- Avoid logging all long-running requests (e.g., `watch`) unless required
- Rotate and protect audit logs like any sensitive logs

---

🔐 Lab complete — audit policy deployed, tested, and validated with security-relevant events captured. 🕵️‍♂️
