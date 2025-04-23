🛡️ Lab: Validating Pod Specs Using OPA Gatekeeper

🧠 Difficulty: Easy  
⏱️ Estimated Time: 15 minutes

🎯 Goal:  
Learn how to use OPA Gatekeeper's validation capabilities to reject Pods at creation time.

📌 Your mission:
1. Install OPA Gatekeeper using Helm in a namespace `gatekeeper-system` (Helm is already installed).
2. Create a validation policy called 'pods-must-have-label-env' that rejects pod created in the namespace `team-blue` taht does not a `env` label.
4. Verify that no validation occur in the namespace `team-green`.
5. Remove OPA Gatekeeper

💡 Tips :

- You can use installation documentation : https://open-policy-agent.github.io/gatekeeper/website/docs/install
- You can use the howto : https://open-policy-agent.github.io/gatekeeper/website/docs/howto

🧰 Context:
- Two namespaces are pre-created: `team-blue` and `team-green`.
- You are free to use any minimal Pod spec to test the behavior (ie `kubectl run`).
- Gatekeeper must be installed and configured by you using Helm.

✅ Expected result:
- A pod without label `env` created in `team-blue` is automatically rejected.
- A pod without label `env` created in `team-green` is possible.
