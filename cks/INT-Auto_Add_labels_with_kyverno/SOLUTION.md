## 🛡️ Auto-Add Labels to Pods with Kyverno



### 🔬 Installation Steps

**1. Install Kyverno with Helm**

Let' have a look on the doc: https://kyverno.io/docs/installation/methods/

```bash
$ helm repo add kyverno https://kyverno.github.io/kyverno/
$ helm repo update
$ helm install kyverno kyverno/kyverno -n kyverno --create-namespace
NAME: kyverno
LAST DEPLOYED: Sun Apr 27 06:42:06 2025
NAMESPACE: kyverno
STATUS: deployed
REVISION: 1
NOTES:
Chart version: 3.4.0
Kyverno version: v1.14.0

Thank you for installing kyverno! Your release is named kyverno.

The following components have been installed in your cluster:
- CRDs
- Admission controller
- Reports controller
- Cleanup controller
- Background controller

⚠️  WARNING: Setting the admission controller replica count below 2 means Kyverno is not running in high availability mode.
⚠️  WARNING: PolicyExceptions are disabled by default. To enable them, set '--enablePolicyException' to true.
💡 Note: There is a trade-off when deciding which approach to take regarding Namespace exclusions. Please see the documentation at https://kyverno.io/docs/installation/#security-vs-operability to understand the risks.

```

Kyverno uses kube-apiserver's Admission webhooks, and there's no need to add a special option to kube-apiserver to “enable” Admission Webhooks.
They've already been natively enabled since Kubernetes v1.9 (for... a long time).

What we need to understand:
- The kube-apiserver automatically exposes two entry points for webhooks:
  - 1. MutatingAdmissionWebhook
  - 2. ValidatingAdmissionWebhook

Client ➔ kube-apiserver
            ⬇️
       MutatingWebhook
            ⬇️
       ValidatingWebhook
            ⬇️
       Request accepted

These two plugins (`MutatingAdmissionWebhook`, `ValidatingAdmissionWebhook`) are already enabled by default in the kube-apiserver's `--enable-admission-plugins` list.

👉 This is what makes it possible to use Kubernetes resources like :

- `MutatingWebhookConfiguration`
- `ValidatingWebhookConfiguration`

and allows Kyverno to register with the API Server without changing anything in the system config.

We can see the webhooks that Kyverno has created : 

```
$ kubectl get mutatingwebhookconfigurations
NAME                                    WEBHOOKS   AGE
kyverno-policy-mutating-webhook-cfg     1          15m
kyverno-resource-mutating-webhook-cfg   0          15m
kyverno-verify-mutating-webhook-cfg     1          15m

$ kubectl get validatingwebhookconfigurations
NAME                                            WEBHOOKS   AGE
kyverno-cel-exception-validating-webhook-cfg    1          16m
kyverno-cleanup-validating-webhook-cfg          1          16m
kyverno-exception-validating-webhook-cfg        1          16m
kyverno-global-context-validating-webhook-cfg   1          16m
kyverno-policy-validating-webhook-cfg           1          16m
kyverno-resource-validating-webhook-cfg         0          16m
kyverno-ttl-validating-webhook-cfg              1          16m
```


We verify pods are running:

```
$ kubectl get pod -n kyverno
NAME                                            READY   STATUS    RESTARTS   AGE
kyverno-admission-controller-5bdb984fff-r2p4n   1/1     Running   0          17m
kyverno-background-controller-d587f468-2kvd9    1/1     Running   0          17m
kyverno-cleanup-controller-55d9bbbdd7-5vwmh     1/1     Running   0          17m
kyverno-reports-controller-7896975cb7-4kkhl     1/1     Running   0          17m
```


**2. Create the namespace `autolabel`**

```
$ k create ns autolabel
namespace/autolabel created
```

**3. Create a Kyverno ClusterPolicy**


We can almost copy the example at https://kyverno.io/docs/writing-policies/mutate/#add-if-not-present-anchor, the namespace is just missing.

Save the following YAML as `clusterpolicy-autolabel.yaml`:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy  # This is a Kyverno ClusterPolicy (applies cluster-wide)
metadata:
  name: add-env-label # Name of the ClusterPolicy
spec:
  rules:
    - name: add-env-label-prod # Name of this specific rule (we can have several)
      match:
        resources:
          kinds:
            - Pod # Apply the rule to Pod resources
          namespaces:
            - autolabel # Only apply in the 'autolabel' namespace
      mutate:  # This is a mutation rule (it modifies the resource)
        patchStrategicMerge:  # Use a strategic merge patch
          metadata:
            labels:
              +(env): prod # If 'env' label does not exist, add 'env: prod'
```

**Explanation:**
- `+(env): prod` means: *"If the label `env` does not exist, add it with the value `prod`. If it exists, leave it unchanged."*

Reference official doc on patching: [Kyverno Patches](https://kyverno.io/docs/writing-policies/mutate/#add-or-update-fields)

Apply the policy:

```
$ kubectl apply -f clusterpolicy-autolabel.yaml
clusterpolicy.kyverno.io/add-env-label created
```

We can see now :

```
$ k get clusterpolicies
NAME            ADMISSION   BACKGROUND   READY   AGE   MESSAGE
add-env-label   true        true         True    64s   Ready

$ k describe clusterpolicies add-env-label 
Name:         add-env-label
Namespace:    
Labels:       <none>
Annotations:  <none>
API Version:  kyverno.io/v1
Kind:         ClusterPolicy
Metadata:
  Creation Timestamp:  2025-04-27T08:23:55Z
  Generation:          1
  Resource Version:    635291
  UID:                 6f6a3ee7-6d86-4640-bde8-bb0604266c4b
Spec:
  Admission:     true
  Background:    true
  Emit Warning:  false
  Rules:
    Match:
      Resources:
        Kinds:
          Pod
        Namespaces:
          autolabel
    Mutate:
      Patch Strategic Merge:
        Metadata:
          Labels:
            +(env):            prod
    Name:                      add-env-label-prod
    Skip Background Requests:  true
  Validation Failure Action:   Audit
Status:
  ...
```

**4. Test the behavior**


- **Deploy a pod without `env` label:**




```
$ k -n autolabel run nginx --image nginx
pod/nginx created

$ k -n autolabel get pod/nginx --show-labels 
NAME    READY   STATUS    RESTARTS   AGE   LABELS
nginx   1/1     Running   0          20s   env=prod,run=nginx
```

✅ We can see `env=prod` in the pod's labels ! The mutation is ok !


- **Deploy a pod with `env=staging` label:**

```
$ kubectl run -n autolabel busy --image=busybox --labels="env=staging" --command -- sleep 3600
pod/busy created
```

We can see the labels :

```$ k -n autolabel get pods --show-labels 
NAME    READY   STATUS    RESTARTS   AGE   LABELS
busy    1/1     Running   0          5s    env=staging
nginx   1/1     Running   0          4m   env=prod,run=nginx
```

✅ We see `env=staging` and no mutation.

### Notes about Kyverno installation warnings


#### ⚠️ 1. Admission Controller Replica Count Warning

**Message:**
> Setting the admission controller replica count below 2 means Kyverno is not running in high availability mode.

**Explanation:**
- Kyverno uses an admission controller to validate and mutate resources.
- With only **1 replica**, if the pod crashes, Kubernetes operations relying on admission control may fail.

**Recommendation:**
- **In production**, set `replicaCount: 2` or more.


#### ⚠️ 2. PolicyExceptions Disabled Warning

**Message:**
> PolicyExceptions are disabled by default. To enable them, set '--enablePolicyException' to true.

**Explanation:**
- Kyverno supports objects called `PolicyException` to allow targeted policy bypasses.
- By default, exceptions are disabled to enforce strict security.

**Recommendation:**
- Only enable exceptions if your use case truly requires it.
- Add `--enablePolicyException=true` in Kyverno's Helm values or manifest.


#### 💡 3. Namespace Exclusion Note

**Message:**
> There is a trade-off when deciding which approach to take regarding Namespace exclusions.

**Explanation:**
- Kyverno excludes some namespaces by default (`kube-system`, etc.) to avoid disrupting critical services.
- Excluding more namespaces can improve cluster stability but decreases overall security.

**Recommendation:**
- Review your namespace exclusions carefully.
- Balance **operability** and **security**.
- See official guidance: [Kyverno - Security vs Operability](https://kyverno.io/docs/installation/#security-vs-operability)

- Doc : [Namespace Exclusions - Security vs Operability](https://kyverno.io/docs/installation/#security-vs-operability)
---

#### Quick Summary

| Warning | Cause | Recommended Action |
|:---|:---|:---|
| Single replica controller | No HA, risk on failure | Set `replicaCount: 2+` |
| PolicyExceptions disabled | Stricter security | Enable only if needed |
| Namespace exclusions | Stability vs Security tradeoff | Review exclusions carefully |




### 🔍 Tips & Good Practices

- **Why a ClusterPolicy?**
  - You could have used a simple `Policy`, but ClusterPolicy ensures the rule is applied cluster-wide if needed (future proof).

- **Kyverno Mutation Rules:**
  - Mutation happens at creation time, not on existing resources.

- **Production Tip:**
  - Always scope your policies (`match`) carefully to avoid unintended side-effects.

---

### 🔗 Useful links
- Kyverno Docs: https://kyverno.io/docs/
- Helm Installation Guide: https://kyverno.io/docs/installation/methods/
- Kyverno Mutation Guide: https://kyverno.io/docs/writing-policies/mutate/

---

✅ **Lab Completed!**

---

