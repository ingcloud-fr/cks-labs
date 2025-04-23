🔐 Lab: Pod Security Standards and Deployment Compatibility

🧠 Difficulty: Intermediate  
⏱️ Estimated Time: 15–20 minutes

🎯 Goal:  
This lab will help you understand how Pod Security Standards (PSS) affect the ability of pods to run in Kubernetes namespaces.

📌 Your mission:
1. Apply the `baseline` PSS level in `warn` mode to the `team-green` namespace, and delete and reapply the deployment.
2. Apply the `baseline` PSS level in `enforce` mode to the `team-orange` namespace. Delete and modify the deployment so that it complies and runs successfully.
3. Apply the `restricted` PSS level in `enforce` mode to the `team-red` namespace. Delete and modify the corresponding deployment so that it can run under the restricted policy.

🧰 Context:
- Three namespaces are created: `team-green`, `team-orange`, and `team-red`.
- Each one contains a basic nginx Deployment (initial spec is not compliant).
- You must manually apply PSS labels to each namespace and fix the deployments accordingly.

✅ Expected result:
- All three nginx deployments are running.
- Each deployment is adjusted only as much as necessary for the enforced PSS level.

💡 The genuine manifests deploiments are in `~/manifests`

