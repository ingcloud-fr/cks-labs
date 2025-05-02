🛡️ Lab: Delete Non-Stateless or Non-Immutable Pods

🧠 Difficulty: Easy  
⏱️ Estimated Time: 10–15 minutes

🎯 Goal:
Enforce Kubernetes best-practices by removing Pods that are either not stateless or not immutable.

📌 Your mission:
1. List all running Pods in the `production` namespace.
2. Identify pods/deployments that are **not stateless or not immutable** 
3. Delete any non-compliant Pods or scale down to 0 non-compliant deployments

🧰 Context:
- All resources are deployed in the `production` namespace.
- A mix of pods and deployments are present for inspection.
- Pods may use volumes (e.g., ConfigMap, emptyDir) and security contexts.

✅ Expected result:
- Only stateless and immutable Pods should remain.
- All Pods violating the conditions should be deleted.
