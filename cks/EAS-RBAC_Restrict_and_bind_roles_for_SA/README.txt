🛡️ Lab: Restrict and Bind Roles for a Service Account

🧠 Difficulty: Easy 
⏱️ Estimated Time: 10 minutes

🎯 Goal:  
You must fix an overly permissive Role and create a new RBAC rule for finer-grained access.

📌 Your mission:

In the namespace `observability`, a Pod named `node-inspector` is running with ServiceAccount `sa-inspect`.

You must:

1. Edit the **existing Role** bound to `sa-inspect` to allow only the following:
   - `get` access on **Pods** (nothing more)
   - `get` access on **deployments** (nothing more)

2. Create a new **Role** named `role-statefulset-update` in the same namespace, allowing:
   - Only `update` operations
   - Only on **StatefulSets**

3. Create a **RoleBinding** named `bind-role-statefulset-update` to bind this new Role to the ServiceAccount `sa-inspect`.

4. Without modifying or deleting the first RoleBinding, verify that:
   - `kubectl auth can-i update statefulsets` returns ✅ for the service account
   - `kubectl auth can-i list deployments` returns ❌

✅ Expected:
- `sa-inspect` can only get Pods and update StatefulSets
- Any other permissions (list, delete, get other resources...) must be denied

🧹 A `reset.sh` script is available to clean the environment.
