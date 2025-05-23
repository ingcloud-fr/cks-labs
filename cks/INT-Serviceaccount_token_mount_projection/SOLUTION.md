# ✅ SOLUTION — CH_token_projection_intermediate

## 🎯 Lab Objective Recap
- Create a ServiceAccount named `project-sa` with `automountServiceAccountToken: false`
- Modify the pod spec of nginx deployment to manually mount a projected token with:
  - custom `audience`
  - short `expirationSeconds`
  - custom mount path

---

## 🧩 Step-by-step Explanation

### 🔹 Step 1: Create Namespace and Service Account


```
$ k create serviceaccount project-sa -n team-blue -o yaml --dry-run=client > project-sa.yaml
```               

Search in the doc *serviceaccount automount* : https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/


```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  creationTimestamp: null
  name: project-sa
  namespace: team-blue
automountServiceAccountToken: false ## ADD
```
➡️ This ensures Kubernetes will **not automatically mount** the default token into any pod using this SA.


```
$ k apply -f project-sa.yaml 
serviceaccount/project-sa created
```

### 🔹 Step 2: Modify Deployment to Use Projected Token

In the doc, search for **serviceaccount projected** : https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#launch-a-pod-using-service-account-token-projection

We modify the `~manifest/nginx.yaml` according to the documentation :

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: team-blue
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      serviceAccountName: project-sa
      containers:
      - name: nginx
        image: nginx
        volumeMounts:         # ADD
        - mountPath: /var/run/secrets/projected-sa/ # ADD
          name: projected-token-vol # ADD
      volumes:                    # ADD
      - name: projected-token-vol # ADD
        projected:                # ADD
          sources:
          - serviceAccountToken:  # ADD
              path: token         # ADD 👈 The token will appear as a file named 'token' inside the mounted directory
              expirationSeconds: 7200 # ADD
              audience: my-secure-audience # ADD

```

➡️ The field `projected.serviceAccountToken` is part of the Kubernetes [TokenRequest API](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#service-account-token-volume-projection).

- `path: token` → the token will be available inside the volume at `/var/run/secrets/projected-sa/token`
- `expirationSeconds: 300` → the token expires after 5 minutes
- `audience: my-secure-audience` → the token is valid only for consumers that validate this audience

---

## 🔍 How to Verify

> 💡 **Tip:** The projected token is a JWT in URL-safe Base64 format. If `base64 -d` complains about invalid input, it's likely due to missing padding. 
> 🧠 Also, always use single quotes around shell blocks to avoid issues with special characters when nesting double quotes inside `kubectl exec`.


1. **Exec into the Pod**:
```
$ kubectl exec -n team-blue -it deploy/nginx -- cat /var/run/secrets/projected-sa/token
eyJhbGciOiJSUzI1NiIsImtpZCI6IkFhbXhCd0JVT3ZBNUxtVl9ieDQ2VjRicV84SFZKU0xHSmNXSmxteDQ3NTQifQ.eyJhdWQiOlsibXktc2VjdXJlLWF1ZGllbmNlIl0sImV4cCI6MTc0NDgwMTEyMiwiaWF0IjoxNzQ0NzkzOTIyLCJpc3MiOiJodHRwczovL2t1YmVybmV0ZXMuZGVmYXVsdC5zdmMuY2x1c3Rlci5sb2NhbCIsImp0aSI6ImQwOTIwZWFmLTA0NDItNDMzYi1hN2ViLWQ1NmJhOWEwNjJhOSIsImt1YmVybmV0ZXMuaW8iOnsibmFtZXNwYWNlIjoidGVhbS1ibHVlIiwibm9kZSI6eyJuYW1lIjoiazhzLW5vZGUwMSIsInVpZCI6ImJjNGJmYTg0LTEzNmQtNGQxYS05M2RiLTVkNWYwN2M1YzIxYSJ9LCJwb2QiOnsibmFtZSI6Im5naW54LTY2NTRmNzlmZmYtODVrcjciLCJ1aWQiOiJhZDYwNjc2ZC0yMTU2LTQ2NjYtYjZkZS1mYTY3NWNlNTc1OGYifSwic2VydmljZWFjY291bnQiOnsibmFtZSI6ImRlZmF1bHQiLCJ1aWQiOiIxMTYzYzU5OS1hZWM1LTRmNDYtYWJhYi0xYzQ5NjFlNjQyNjAifX0sIm5iZiI6MTc0NDc5MzkyMiwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50OnRlYW0tYmx1ZTpkZWZhdWx0In0.cEFBmnCeyRxA5l7IfzXlHXE6plAv_i__cQU7IEquxjt0tFaijBtdOdLaOeY_QwN_Irj0jzOPqG8UiptcFV1lTNbVbtgC0O6ECSc7PL4D72KRO_3xjH7wXD0OaYLefdeUtQ2qpMQ7mL6bLGP3vgOInL1J6FXUlQxBNUivQUhneywo4r6bGJev7RrxR1M3ME_OwlC-h3wqF5XmxiomnfzXxAcjv9rvkQuPd1ZNzNS69K3UJJ3bV5OG3PcUhbJcmP3u88WNj_AI4xE4CyPUP_ZGIam94U2rTYmD76RgXbGmlHOILDvkPWUmARNGZyuzf9YGe99T8Dr0kLuHaz9ms1coiQ
```

Note about token format : `HEADER.PAYLOAD.SIGNATURE` on one line.

2. **Decode the JWT token**:

```
$ TOKEN=$(kubectl exec -n team-blue -it deploy/nginx -- sh -c 'cat /var/run/secrets/projected-sa/token | cut -d "." -f2 | base64 -d')
command terminated with exit code 1

$ echo $TOKEN
{"aud":["my-secure-audience"],"exp":1746227556,"iat":1746220356,"iss":"https://kubernetes.default.svc.cluster.local","jti":"fda0cf11-26f8-4a6e-b805-4a5fc6d4e457","kubernetes.io":{"namespace":"team-blue","node":{"name":"k8s-node01","uid":"276fb402-b57c-403b-a6de-6482db172c52"},"pod":{"name":"nginx-556fbd85d7-jkbsw","uid":"fa69e99d-accc-4566-b646-9fef7936cdfe"},"serviceaccount":{"name":"project-sa","uid":"e61532ba-6023-4524-9544-2177bc2272c1"}},"nbf":1746220356,"sub":"system:serviceaccount:team-blue:project-sa"}base64: invalid input

```

We can see name of the token `team-blue:project-sa` the expiration `"exp":1744801122`


## 💡 Best Practices (Production)

- Always disable default token automount unless needed (`automountServiceAccountToken: false`)
- Use token projection with **specific audiences** to reduce misuse
- Prefer **short-lived tokens** for sensitive workloads
- Use **network policies** to limit the exposure of services that validate those tokens
- Rotate ServiceAccount tokens regularly via CI/CD workflows

---

✅ Lab completed!
