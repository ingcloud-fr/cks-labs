🛡️  Lab: Enforce Mutual Authentication with Cilium

🧠 Difficulty: Intermediate  
🧩 Domain: Minimize Microservice Vulnerabilities  
⏱️  Estimated Time: 20–25 minutes

🎯 Goal: Implement a mutual authentication policy between workloads using Cilium's advanced features.

📌 Your mission:
1. Explore the communication pattern between `client`, `server`, and `untrusted` Pods in the namespace `team-yellow`.
2. Write and apply a `CiliumNetworkPolicy` called `enforce-access` that:
   - Applies to the `server` Pod
   - Only allows ingress HTTP traffic from the `client` Pod
   - With `POST` only method on URL `/anything` (you can test with curl with `curl -XPOST` and `-XGET`)
   - Enforces mutual authentication (mTLS)
3. Confirm that:
   - The `client` Pod can access the `server` over HTTP
   - The `untrusted` Pod is blocked from accessing the server
4. (Optional) Change the path in CNP rule to allow `/anything?foo=bar`

🧰 Context:
- The namespace `team-yellow` is already deployed.
- The `server` Pod exposes an HTTP endpoint on port 8080.
- The `client` Pod uses `curl -XPOST` or `curl -XGET` for testing.
- The `untrusted` Pod simulates unauthorized access.

✅ Expected:
- Traffic from the `client` to the `server` should succeed with POST method only.
- Traffic from the `untrusted` Pod should fail.
- Only mutually authenticated traffic should be allowed.

🧹 A `reset.sh` script is provided to clean the environment between runs.
