## Solution: Enforce baseline Pod Security Standard in a Namespace

### 🔍 Step-by-step Solution

#### 1. Inspect 

```
$ k -n team-blue get all --show-labels 
NAME                                    READY   STATUS    RESTARTS   AGE     LABELS
pod/hostile-container-8754dcc67-g7fmk   1/1     Running   0          7m39s   app=backend,pod-template-hash=8754dcc67

NAME                                READY   UP-TO-DATE   AVAILABLE   AGE     LABELS
deployment.apps/hostile-container   1/1     1            1           7m39s   <none>

NAME                                          DESIRED   CURRENT   READY   AGE     LABELS
replicaset.apps/hostile-container-8754dcc67   1         1         1       7m39s   app=backend,pod-template-hash=8754dcc67

```

Check if any Pod Security labels are currently set:

```
$ k get ns team-blue --show-labels
```

No PSS/PSA label on the team-blue-namespace.


#### 2. Add the `baseline` enforcement labels to the Namespace

Search for PSA in the kubernetes documentation : https://kubernetes.io/docs/concepts/security/pod-security-admission/

From the doc : *Kubernetes defines a set of labels that you can set to define which of the predefined Pod Security Standard levels you want to use for a namespace. The label you select defines what action the control plane takes if a potential violation is detected.*

So to block Pods that violate the `baseline` policy, apply the following labels:

```
$ k label namespace team-blue pod-security.kubernetes.io/enforce=baseline
```

There is a warning :

```
Warning: existing pods in namespace "team-blue" violate the new PodSecurity enforce level "baseline:latest"
Warning: hostile-container-8754dcc67-g7fmk: hostPath volumes
namespace/team-blue labeled
```

- Note : We an also put the version (optional) :

```
$ k label namespace team-blue 
  pod-security.kubernetes.io/enforce=baseline \
  pod-security.kubernetes.io/enforce-version=latest
```

This enforces the **baseline** Pod Security Standard in the namespace `team-blue` using the **most recent version** available in the cluster.

#### 3. Delete the current Pod

Force the deletion of the existing Pod from the Deployment:

```
$ k -n team-blue delete pod/hostile-container-8754dcc67-g7fmk 
pod "hostile-container-8754dcc67-g7fmk" deleted
```


Or with le label :

```
$ k -n team-blue delete pod -l app=backend
```

#### 4. Observe the Deployment behavior


We check the deployment :

```
$ k -n team-blue get all
NAME                                READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/hostile-container   0/1     0            0           11m

NAME                                          DESIRED   CURRENT   READY   AGE
replicaset.apps/hostile-container-8754dcc67   1         0         0       11m

```

We can see that there is no pods, and the READY status of the deployment is `0/1`.


Then check for events related to the Deployment:

```bash
$ k get events -n team-blue --sort-by=.lastTimestamp
3m1s        Warning   FailedCreate        replicaset/hostile-container-8754dcc67   Error creating: pods "hostile-container-8754dcc67-rtm59" is forbidden: violates PodSecurity "baseline:latest": hostPath volumes (volume "containerd-socket")
3m1s        Warning   FailedCreate        replicaset/hostile-container-8754dcc67   Error creating: pods "hostile-container-8754dcc67-pctqg" is forbidden: violates PodSecurity "baseline:latest": hostPath volumes (volume "containerd-socket")
3m          Warning   FailedCreate        replicaset/hostile-container-8754dcc67   Error creating: pods "hostile-container-8754dcc67-clqkz" is forbidden: violates PodSecurity "baseline:latest": hostPath volumes (volume "containerd-socket")
2m21s       Warning   FailedCreate        replicaset/hostile-container-8754dcc67   (combined from similar events): Error creating: pods "hostile-container-8754dcc67-4ln5k" is forbidden: violates PodSecurity "baseline:latest": hostPath volumes (volume "containerd-socket")
```

This confirms that the `baseline` policy correctly blocked the Pod from being recreated.

In mode *baseline*, `hostPath` volumes are not allowed :https://kubernetes.io/docs/concepts/security/pod-security-standards/#baseline

### ✅ Best Practices & Tips

* **Never allow hostPath** volumes unless absolutely necessary. They grant access to the node filesystem.
* The `restricted` policy level blocks even more features (like host networking or privileged containers) and is recommended for production.
* Use `enforce`, `warn`, and `audit` labels together in production to enforce policy while monitoring other violations.

### 📚 References

* [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
* [Pod Security Admission](https://kubernetes.io/docs/concepts/security/pod-security-admission/)
