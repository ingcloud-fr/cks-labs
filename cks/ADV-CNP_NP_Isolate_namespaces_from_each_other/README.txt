🛡️ Lab: Isolate Team Namespaces with NetworkPolicy and CiliumNetworkPolicy

🧠 Difficulty: Advanced  
⏱️ Estimated Time: 20 minutes

🎯 Goal:  
You must ensure that pods can only communicate with other pods from the same namespace.  
Pods from different namespaces should not be able to reach each other.

📌 Your mission:

1. In each of the namespaces `team-blue`, `team-green`:
   - create a `NetworkPolicy` named `allow-same-namespace-only`
   - only allow ingress traffic **from the same namespace** on **all pods**

2. Remove the NetworkPolicy `allow-same-namespace-only` in both namespaces.
   Create the same rule using a `CiliumNetworkPolicy` named `cnp-allow-same-namespace-only`

✅ Expected:
- Pods in the same namespace can successfully connect to each other (e.g. `curl nginx`)
- Pods from other namespaces should fail to connect

🧹 A reset.sh script is provided to clean up the lab environment.
