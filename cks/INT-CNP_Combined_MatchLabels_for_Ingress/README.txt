🌐 Lab: Create a CiliumNetworkPolicy with Combined MatchLabels for Ingress

🧠 Difficulty: Intermediate
🧩 Domain: Minimize Microservice Vulnerabilities
⏱️ Estimated Time: 15–20 minutes

🎯 Goal:  
Restrict access to the `api-server` Pod only to specific Pods based on namespace and label.

📌 Your mission:
1. Create a `CiliumNetworkPolicy` named `allow-ingress-strict` in the `team-app` namespace.
2. The policy must:
   - Select Pods labeled `app=api` (i.e., the `api-server` Pod).
   - Allow **Ingress** traffic **only** from Pods that:
     - Belong to namespace `production` **and** have the label `policy=strict`.
     - OR belong to namespace `staging` **and** have the label `policy=strict`.
   - Restrict access **only** to TCP port `80`.

🧰 Context:
- Namespaces `production`, `staging`, and `team-app` are created.
- Several Pods are deployed in `production` and `staging` with different labels.

✅ Expected result:
- Only Pods in `production` or `staging` with `policy=strict` should access `api-server` on port 80.
- Pods without the `policy=strict` label must be blocked.
- Pods from other namespaces must be blocked.
- Traffic to other ports must be blocked.

🧹 A `reset.sh` script is available to clean the cluster between attempts.
