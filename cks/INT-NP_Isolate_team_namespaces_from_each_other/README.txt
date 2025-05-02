🛡️ Lab: Isolate Team Namespaces with Network Policies

🧠 Difficulty: Intermediate  
⏱️ Estimated Time: 15 minutes

🎯 Goal:  
You must ensure that pods can only communicate with other pods from the same namespace.  
Pods from different namespaces should not be able to reach each other.

📌 Your mission:

1. In each of the namespaces `team-blue`, `team-green`, and `team-red`:
   - create a NetworkPolicy named `allow-same-namespace-only`
   - only allow ingress traffic **from the same namespace**

2. Use the label `app: nginx` to select the pods in each namespace.

3. Do not block egress traffic.

✅ Expected:
- Pods in the same namespace can successfully connect to each other (e.g. `curl nginx`)
- Pods from other namespaces should fail to connect

🧹 A reset.sh script is provided to clean up the lab environment.
