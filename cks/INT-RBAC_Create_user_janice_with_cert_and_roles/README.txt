🛡️ Lab: Create User Janice with Certificate and Roles

🧠 Difficulty: Intermediate  
⏱️ Estimated Time: 15 minutes

🎯 Goal:  
You must create a Kubernetes user named `janice`, configure certificate-based authentication with API, and assign namespace-scoped RBAC permissions.

📌 Your mission:

1. Generate a private key and certificate signing request (CSR) for `janice` using `openssl` :

   $ openssl genrsa -out janice.key 2048
   $ openssl req -new -key janice.key -out janice.csr -subj "/CN=janice/O=janice-group"

2. Submit the CSR to the Kubernetes API and approve it
3. Create a kubeconfig file called `janice-kubeconfig` so that `janice` can use `kubectl`. Embed the certificates in the file.
4. Create a Role called `pod-reader` in the namespace `team-green` that:
   - Allows only `get`, `list`, and `watch` on Pods
5. Create a RoleBinding called `janice-binding` in the same namespace `team-green` binding the Role to user `janice`
6. Use `kubectl auth can-i` to verify permissions from janice’s perspective

✅ Expected:
- `janice` can get/list/watch pods in `janice-space`
- Any other action (e.g. create/delete) or access to other resources should be denied

📁 You can use a separate kubeconfig (`janice.kubeconfig`) and test it like so:

kubectl --kubeconfig=janice.kubeconfig get pods -n janice-space
kubectl --kubeconfig=janice.kubeconfig auth can-i delete pods -n janice-space

🧹 A reset.sh script is available to remove the CSR, Role, RoleBinding, and the namespace.