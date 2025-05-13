🛡️ Lab: Inject a ServiceAccount token into a Pod from a Secret

🧠 Difficulty: Intermediate  
🧩 Domain: Minimize Microservice Vulnerabilities  
⏱️ Estimated Time: 15–25 minutes

🎯 Goal:  
Manually generate a time-limited ServiceAccount token and inject it into a Pod using different techniques (environment variable or projected volume).

📌 Your mission:
1. Create a ServiceAccount named `custom-bot` in the `team-blue` namespace.
2. Generate a time-limited token (20 minutes) using `kubectl create token` and save it to a file.
3. Create a Secret named `custom-bot-token` from that file.
4. Create a RoleBinding named `rb-custom-bot` in the `team-blue` namespace, using the existing `view` ClusterRole and linking it to the `custom-bot` ServiceAccount.
5. Deploy a Pod using the `curlimages/curl` image with a `sleep` command to keep it alive.
6. Inject the token into the Pod using (one of your choice):
   - Option 1: An environment variable (`valueFrom.secretKeyRef`)
   - Option 2: A projected volume
7. Connect into the Pod and test the Kubernetes API with `curl` using the injected token.
   You can use `curl -sSk -H "Authorization: Bearer $TOKEN"` to pass the TOKEN to the API server
8. (Bonus) Decode the token and analyze its claims (`exp`, `aud`, `sub`, etc.)

🧰 Context:
- The `team-blue` namespace is already created.
- You will use tools available inside the Pod like `curl`, `base64`, and optionally `jq` to inspect the token.

✅ Expected result:
- The Pod should access the Kubernetes API using the injected token.
- You should see a valid API JSON response (from `/api`) using the token.
- You should understand the difference between the two token injection methods.
- You should be able to identify the ServiceAccount identity in the decoded token.

🧹 A `reset.sh` script is available to clean the cluster between attempts.
