🛡️ Lab: Restrict access to products-service Pod

🧠 Difficulty: Intermediate
🧩 Domain: Minimize Microservice Vulnerabilities
⏱️ Estimated Time: 10–15 minutes

🎯 Goal:  
Create a NetworkPolicy named `pod-restriction` to restrict ingress access to the Pod `products-pod` running in the namespace `development`.

Only allow connections from:
- Pods located in the namespace `team-qa`
- Pods with label `env: staging`, from any namespace

📌 Your mission:
1. Create a NetworkPolicy named `pod-restriction` in the `development` namespace.
2. Configure the policy to restrict ingress traffic accordingly.
3. Apply and validate the NetworkPolicy.

🧰 Context:
- A namespace `development` has been created.
- A namespace `team-qa` has been created.
- A Pod named `products-pod` is running in `development`.
- A Service `products-service` is running in `development`.

✅ Expected result:
- Only Pods from namespace `team-qa` or Pods with label `env: staging` in any namespace can access `products-service`.
- All other traffic should be denied.

🧹 A `reset.sh` script is available to clean the cluster between attempts.
