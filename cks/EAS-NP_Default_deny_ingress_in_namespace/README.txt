🛡️ Lab: Default-Deny Ingress Policy in a Namespace

🧠 Difficulty: Beginner  
⏱️ Estimated Time: 5–10 minutes

🎯 Goal:  
You must create a default-deny `NetworkPolicy` for all incoming traffic in the namespace `production`.

📌 Your mission:

1. In the namespace `production`, a pod is already running (app=nginx)
2. Create a `NetworkPolicy` named `defaultdeny`
3. The policy must:
   - Deny all **Ingress** traffic to all pods in the namespace
   - Apply to **every pod** in the `production` namespace

✅ Expected:
- No pod in the namespace can receive traffic from another pod (even from the same namespace)
- You can confirm this by testing connectivity with `kubectl exec curl -- curl nginx.production`

🧹 A `reset.sh` script is available to clean up the namespace and resources.
