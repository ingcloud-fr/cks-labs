# ✅ Solution – Enforcing Required Labels with Gatekeeper

We base our implementation on the official Gatekeeper how-to guide:
https://open-policy-agent.github.io/gatekeeper/website/docs/howto

🔧 However, the example targets `Namespaces`, while here we are targeting `Pods`. So some adaptations are required.

---

## 📐 ConstraintTemplate (Unchanged)

The constraint template remains the same. According to the documentation:
> *"Here is an example constraint template that requires all labels described by the constraint to be present"*

```yaml
# k8requiredlabelstemplate.yaml 
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8srequiredlabels # lower case of the kind K8sRequiredLabels
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredLabels
      validation:
        # Schema for the `parameters` field
        openAPIV3Schema:
          type: object
          properties:
            labels:
              type: array
              items:
                type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredlabels

        violation[{"msg": msg, "details": {"missing_labels": missing}}] {
          provided := {label | input.review.object.metadata.labels[label]}
          required := {label | label := input.parameters.labels[_]}
          missing := required - provided
          count(missing) > 0
          msg := sprintf("you must provide labels: %v", [missing])
        }
```

## ✏️ Constraint (Adapted for Pods)

We modify the constraint to match Pods in the namespace `team-blue`, and to require the `env` label:

```yaml
# k8requiredlabels.yaml 
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: 
     pods-must-have-label-env # Change the name
spec:
  match:
    namespaces: ["team-blue"] # Add (see the doc just below - match section)
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"] # Change (see api-resource for the kind)
  parameters:
    labels: ["env"]  # Change
```

💡 To identify the kind of a resource:
```bash
$ kubectl api-resources
...
pods                                po      v1   true   Pod
```
> ✅ The kind is `Pod`, not `pods`

## 🚀 Apply the Files

```bash
$ kubectl apply -f k8requiredlabels.yaml
k8srequiredlabels.constraints.gatekeeper.sh/pods-must-have-label-env configured

$ kubectl apply -f k8requiredlabelstemplate.yaml
constrainttemplate.templates.gatekeeper.sh/k8srequiredlabels configured
```

Verify:
```bash
$ kubectl get constrainttemplates.templates.gatekeeper.sh
NAME                AGE
k8srequiredlabels   4m
```

## ✅ Test the Validation

Try creating a pod **without** the required label:
```bash
$ kubectl -n team-blue run nginx --image nginx
Error from server (Forbidden): admission webhook "validation.gatekeeper.sh" denied the request: [pods-must-have-label-env] you must provide labels: {"env"}
```
✅ The request was denied as expected.

Try again **with** the label:
```bash
$ kubectl -n team-blue run nginx --image nginx --labels env=prod
pod/nginx created
```
✅ This time the pod is accepted.

Check that other namespaces are **not affected**:
```bash
$ kubectl -n team-green run nginx --image nginx
pod/nginx created
```
✅ Everything is working as intended.

---

## 🧹 Cleanup

Uninstall Gatekeeper:
```bash
$ helm list -n gatekeeper-system
$ helm uninstall gatekeeper -n gatekeeper-system
release "gatekeeper" uninstalled
```

You can also reset the lab:
```bash
$ ./reset.sh
```