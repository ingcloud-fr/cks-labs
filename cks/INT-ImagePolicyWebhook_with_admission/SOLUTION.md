## Solution: Configure ImagePolicyWebhook with Admission Webhook

### ✅ Objective Recap
You were asked to:
- Create an `ImagePolicyWebhook` configuration referencing the pre-deployed webhook
- Update the `kube-apiserver` to use this webhook config
- Enforce a fail-closed policy rejecting `busybox` images

---

### 🛠️ Step-by-Step Solution

Search for **admission** or **ImagePolicyWebhook** in Kubernetes documentation : https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#imagepolicywebhook


#### 1. Create the `imagepolicyconfig.yaml` file:

We can see :

```
$ k -n webhook-system get all
NAME                           READY   STATUS    RESTARTS   AGE
pod/webhook-78745d9755-8dltt   1/1     Running   0          50s

NAME                      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/webhook-service   ClusterIP   10.99.177.209   <none>        443/TCP   50s

NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/webhook   1/1     1            1           50s

NAME                                 DESIRED   CURRENT   READY   AGE
replicaset.apps/webhook-78745d9755   1         1         1       50s

```

We have the webhook server kubeconfig file :

```
$ ls -la /etc/kubernetes/security/webhook/
total 16
drwxr-xr-x 2 root root 4096 Apr 26 06:42 .
drwxr-xr-x 3 root root 4096 Apr 26 06:42 ..
-rw------- 1 root root 5994 Apr 26 06:42 webhook-kubeconfig.yaml
```

So we can create `/etc/kubernetes/security/webhook/imagepolicyconfig.yaml` using `webhook-kubeconfig.yaml` :

```yaml
imagePolicy:
  kubeConfigFile: /etc/kubernetes/security/webhook/webhook-kubeconfig.yaml # Path of the server kubeconfig
  allowTTL: 100
  denyTTL: 100
  retryBackoff: 500
  defaultAllow: false
```
Now create the `/etc/kubernetes/security/webhook/admission-config.yaml` file (it's this file in `--admission-control-config-file:` in kube-apiserver configuration) :

```yaml
apiVersion: apiserver.config.k8s.io/v1
kind: AdmissionConfiguration
plugins:
  - name: ImagePolicyWebhook
    path: /etc/kubernetes/security/webhook/imagepolicyconfig.yaml
```

Alternatively, you can embed the configuration directly in the file `/etc/kubernetes/security/webhook/admission-config.yaml` :

```yaml
apiVersion: apiserver.config.k8s.io/v1
kind: AdmissionConfiguration
plugins:
  - name: ImagePolicyWebhook
    configuration:
      imagePolicy:
        kubeConfigFile: /etc/kubernetes/security/webhook/webhook-kubeconfig.yaml
        allowTTL: 50
        denyTTL: 50
        retryBackoff: 500
        defaultAllow: true
```

#### 2. Modify the `kube-apiserver` manifest (usually ):

In `/etc/kubernetes/manifests/kube-apiserver.yaml`, add the following line:

```yaml
- --admission-control-config-file=/etc/kubernetes/security/webhook/admission-config.yaml
```

And we add `ImagePolicyWebhook` to the `--enable-admission-plugins=` :


```yaml
- --enable-admission-plugins=NodeRestriction,ImagePolicyWebhook
```

We also need to do a mount :

```yaml
  ...
    volumeMounts:
    - mountPath: /etc/kubernetes/security/webhook
      name: webhook-config
      readOnly: true
  ...
  volumes:
  - hostPath:
      path: /etc/kubernetes/security/webhook
      type: DirectoryOrCreate
    name: webhook-config
```


✅ Notes:
- You must keep existing enabled plugins and append `ImagePolicyWebhook`
- Ensure the kubeconfig path exists and is accessible by the kube-apiserver
- No need to restart: as a static Pod, the kupe-apiserver will auto-restart it on manifest change

### 🔍 Test the Webhook

#### Try to deploy a Pod using busybox:

```
$ k run pod-busy --image busy
Error from server (Forbidden): pods "pod-busy" is forbidden: image policy webhook backend denied one or more images: Images non autorisées : busy
```
✅ Expected: **Rejected** with a message from the webhook.

#### Try with nginx:
```
$ k run pod-nginx --image nginx
pod/pod-nginx created

```
✅ Expected: **Accepted**.


### 🧠 Good Practices
- Always use `defaultAllow: false` in production (fail-closed)
- Restrict access to `/etc/kubernetes/security/` to prevent tampering
- Validate the webhook TLS certs and refresh them before expiry
- Monitor the API server logs for admission errors or webhook timeouts


### 📚 References
- Kubernetes admission webhook docs:
  https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#imagepolicywebhook
  


