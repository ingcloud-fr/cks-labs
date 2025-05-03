🛡️ Lab: Limit Ingress Between Pods with NetworkPolicies

🧠 Difficulty: Intermediate  
🧩 Domain : Cluster Hardening  
⏱️  Estimated Time: 10–15 minutes

🎯 Goal:  
Use Kubernetes Network Policies to restrict ingress traffic between Pods in a namespace, and selectively allow traffic based on labels and ports.

📌 Your mission:

1. Create a NetworkPolicy named `ingress-deny` in the namespace `team-green`:
   - It must **deny all ingress** traffic between Pods inside the namespace `team-green`.
   - Communication from Pods outside `team-green` should also be blocked.

2. Verify that:
   - The `frontend` Pod **cannot** reach the `backend` Pod using `wget` or `curl`.
   - The test Pod in the `default` namespace **cannot** reach the backend either.

3. Create another NetworkPolicy named `ingress-allow-backend` in the same namespace:
   - It should **allow ingress** traffic **only** from Pods with label `role=frontend` in namespace `team-green`.
   - The allowed port is **3000**.

4. Verify again using `wget` from the `frontend` Pod that access is now granted.
   - All other Pods should still be denied.

🧰 Context:
- A namespace `team-green` is pre-created.
- A `frontend` Pod and a `backend` Pod are deployed in that namespace.
- The `backend` Pod is listening on port **3000**.
- A third Pod (named `tester`) is deployed in the `default` namespace for validation.

✅ Expected result:
- The `backend` Pod should be unreachable until the allow rule is applied.
- Only the `frontend` Pod should be able to connect on port 3000 after the policy is created.
- The `tester` Pod in `default` must remain blocked.

🧹 A `reset.sh` script is available to clean the cluster between attempts.
