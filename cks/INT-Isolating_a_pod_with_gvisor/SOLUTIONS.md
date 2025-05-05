# Solution

## Create the runtime class

Search for **runtime class** on Kubernetes documentation : https://kubernetes.io/docs/concepts/containers/runtime-class/ pour trouver des exemples :


```yaml
# runtimeclass-runsc.yaml 
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: gvisor
handler: runsc
```

```
$ k apply -f runtimeclass-runsc.yaml 
```

We can see :

```
$ kubectl get runtimeclass
NAME     HANDLER   AGE
gvisor   runsc     7m
```

## Test

We create a test pod in the `team-red` namespace:

```
$ k run pod-gvisor --image ubuntu -n team-red --dry-run=client -o yaml --command -- sleep 3600 > pod-gvisor.yaml
```

We edit the generated yaml to add the `runtimeClassName` :

```yaml
# pod-gvisor.yaml 
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod-gvisor
  name: pod-gvisor
  namespace: team-red
spec:
  runtimeClassName: gvisor # ADD
  containers:
  - command:
    - sleep
    - "3600"
    image: ubuntu
    name: pod-gvisor
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

We lunch the pod and check :

```
$ k apply -f pod-gvisor.yaml 
pod/pod-gvisor created

$ k -n team-red get pods -o wide
NAME         READY   STATUS    RESTARTS   AGE   IP           NODE         NOMINATED NODE   READINESS GATES
pod-gvisor   1/1     Running   0          13s   10.0.1.128   k8s-node01   <none>           <none>


$ k -n team-red describe pod/pod-gvisor 
...
Runtime Class Name:  gvisor
...
```
