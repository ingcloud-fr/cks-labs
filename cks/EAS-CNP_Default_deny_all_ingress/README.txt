🛡️ Lab: Apply a Default-Deny Ingress Policy with Cilium

🧠 Difficulty: Beginner
🧩 Domain : Cluster Hardening
⏱️ Estimated Time: 10–15 minutes

🎯 Goal:  
Discover how Cilium Network Policies (CNP) behave by default, and apply a policy to restrict ingress traffic for all Pods in a namespace.

📌 Your mission:
1. A namespace `team-blue` already exists with two Pods: `frontend` and `backend`
2. The backend Pod exposes port 8080 and responds to HTTP requests
3. By default, the frontend Pod is able to reach the backend Pod
4. Apply a CiliumNetworkPolicy named `default-deny-ingress`in the namespace `team-blue` that denies all ingress traffic
5. Verify that communication between frontend and backend is blocked
6. Update the CiliumNetworkPolicy to allow only the frontend to access the backend on port 8080

✅ Expected result:
- The frontend Pod cannot access the backend after the default-deny policy is applied
- After the rule is refined, only the frontend can access the backend on port 8080

🧹 A `reset.sh` script is available to clean the cluster between attempts.
