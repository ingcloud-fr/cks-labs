🛡️ Lab: CiliumNetworkPolicy using matchExpressions with Namespaces and Labels

🧠 Difficulty: Advanced  
🧩 Domain: Minimize Microservice Vulnerabilities  
⏱️ Estimated Time: 20 minutes

🎯 Goal:  
Create a CiliumNetworkPolicy that restricts Ingress access based on both the namespace and specific Pod labels using `matchExpressions`.

📌 Your mission:

1. Create a CiliumNetworkPolicy named `restrict-namespaces-and-labels` to protect the `api-server` Pod.  
Only allow Ingress traffic from Pods that:
- Belong to namespace `production` or `staging`  
- *AND* have label `policy=strict`  
Use `matchExpressions` to define this logic in `fromEndpoints`.
Test your rule

2. Change the rule, still to protect the `api-server` Pod :
Only allow Ingress traffic from Pods that:
- Belong to namespace `production` or `staging`  
- *OR* have label `policy=strict`  
Still use `matchExpressions` to define this logic in `fromEndpoints`.


🧰 Context:
- Namespaces `team-app`, `production`, and `staging` are created.
- Pods use the `wbitt/network-multitool` image for easy testing.
- A Service `api-service` exposes the `api-server`.

✅ Expected result:
- Only correctly labeled Pods in `production` or `staging` can access `api-server`.
- Other Pods, even from allowed namespaces
