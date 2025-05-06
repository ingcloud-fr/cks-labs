🛡️ Lab: Combine Ingress and Egress with CiliumNetworkPolicy

🧠 Difficulty: Intermediate
🧩 Domain: Minimize Microservice Vulnerabilities
⏱️ Estimated Time: 20 minutes

🎯 Goal:
Create a CiliumNetworkPolicy that simultaneously controls Ingress and Egress at Layer 4 (TCP ports).

📌 Your mission:

Create 2 CiliumNetworkPolicies :
   - One named `named `restrict-l4-ingress` that restrict Ingress on the `server`:
     - Accept traffic on port 8080 only from Pods labeled `role=frontend`.
     - Accept traffic on port 3306 only from Pods labeled `role=backup`.
   - A second named `restrict-l4-egress` that restrict Egress on `backup` Pod:
     - Allow `backup` to access only `server` port 3306.
     - ... and maybe another one ... just test !

🧰 Context:
- Namespace `team-app` is created.
- Pods use the `wbitt/network-multitool` image for easy connectivity tests.
- On server, the port 8080 is https, the port 3306 is http (for the tests)
- A Service `server-service` exposes the server Pod internally.

✅ Expected result:
- `frontend` ➔ server:8080 : ✅ OK
- `frontend` ➔ server:3306 : ❌ Denied
- `backup` ➔ server:3306 : ✅ OK
- `backup` ➔ server:8080 : ❌ Denied

🧹 A `reset.sh` script is available to clean the cluster between attempts.
