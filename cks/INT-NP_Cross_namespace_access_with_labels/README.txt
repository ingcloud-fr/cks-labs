🛡️ Lab: Cross-Namespace Access with Labels

🧠 Difficulty: Intermediate  
⏱️ Estimated Time: 10 minutes

🎯 Goal:  
Allow pods to communicate across namespaces **only if they share a specific label**.

📌 Your mission:

1. Two namespaces are created: `team-orange` and `team-blue`
2. Each namespace contains a pod labeled `app=api`
3. Some pods are also labeled with `access=cross-team`

🔒 Your task:
- Create a NetworkPolicy named `allow-across-team` in `team-orange` to only allow ingress to the `api` pod if the **source pod** has the label `access=cross-team`, regardless of its namespace

✅ Expected:
- A pod in `team-blue` with `access=cross-team` can reach the API pod in `team-orange`
- A pod in `team-blue` without the label is blocked

🧹 A reset.sh script is provided to clean up the lab environment.
