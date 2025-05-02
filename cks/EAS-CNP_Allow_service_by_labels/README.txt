🛡️ Lab: Allow traffic using CiliumNetworkPolicy and labels

🧠 Difficulty: Easy  
🧩 Domain : Cluster Hardening  
⏱️ Estimated Time: 10 minutes

🎯 Goal:  
Use CiliumNetworkPolicy to allow ingress traffic to a pod based on the labels of the source Pod.

📌 Your mission:
1. Create a `CiliumNetworkPolicy` named `allow-client-to-backend` that:
   - Allows ingress traffic to pods with label `role=backend`
   - But only if the source Pod has label `role=client`
2. All other ingress traffic to the backend pod must be denied.
3. Verify that:
   - The pod with label `role=client` can reach the backend
   - Other pods cannot reach the backend

🧰 Context:
- Namespace `team-green` is created.
- A pod `client` is deployed with label `role=client`
- A pod `backend` is deployed with label `role=backend`
- A third pod `intruder` without label is also present

✅ Expected result:
- Only the `client` pod can access the `backend` on port 8080
- Access from `intruder` is denied (connection times out or fails)

🧹 A `reset.sh` script is available to clean the cluster between attempts.
