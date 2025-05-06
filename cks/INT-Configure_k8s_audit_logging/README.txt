🛡️ Lab: Configure Kubernetes Audit Logging

🧠 Difficulty: Advanced  
⏱️ Estimated Time: 25–35 minutes

🎯 Goal:  
Enable audit logging in Kubernetes and verify that specific security-related actions are properly logged.

📌 Your mission:
1. Configure Kubernetes API server to enable audit logging using the following configuration:
   - Audit policy file: `/etc/kubernetes/audit/prod-policy.yaml`
   - Log output file: `/var/log/kubernetes/audit/audit-prod.log`
   - Log retention: 30 days
   - Maximum backups: 2 files

2. Apply an audit policy that logs the following:
   - ✅ Pod creation **and deletion** (any namespace) → `RequestResponse`
   - ✅ Pod logs access (e.g. `kubectl logs`) in any namespace → `Metadata` (no specific verb, logs everything)
   - ✅ Secret modification and deletion (any namespace) → `Metadata`
   - ✅ ConfigMap deletion (in `kube-system`) → `Request`
   - ✅ Deployment modification in `team-pink` → `Request`
   - ❌ Dot not log anything in `RequestReceived` stage 
   - ❌ Requests to `/api*` paths (non-resource URLs) → must **not** be logged

3. For testing, you must manually:
   - Modify the existing deployment in the `team-pink` namespace
   - Create and delete a secret in the `default` namespace
   - Create and delete a ConfigMap in the `kube-system` namespace
   - Create and delete a pod in any namespace (e.g. `default`)
   - Access logs from a running pod (e.g. `kubectl logs`)

🧰 Context:
- A namespace `team-pink` is created
- A deployment is already running in `team-pink` (you must modify it)

📁 Reference:
Kubernetes audit policy documentation:  
https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/

✅ Expected result:
- The configured audit policy logs only the expected events
- The log file `/var/log/kubernetes/audit/audit-prod.log` should contain:
   - Pod `create` and `delete`
   - `get` on pod logs
   - `delete` of secrets and configmaps (as per policy)
   - Deployment `update`
- No logs should appear for `/api*` access (filtered by policy)

🧹 A `reset.sh` script is available to clean the cluster between attempts.
