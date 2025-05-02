🛡️ Lab: Escaping Secret Restrictions with Pod Workarounds

🧠 Difficulty: Advanced 
⏱️ Estimated Time: 20 minutes

🎯 Goal:
A user with restricted RBAC permissions has somehow managed to access Kubernetes Secrets. Your task is to explore how this could happen and extract the values of three secrets, without having direct access to them.

📌 Your mission:

- Switch to the provided restricted user context with `kubectl config use-context restricted@infra-prod`
- Investigate the workloads running in the `team-red` namespace.
- Extract the values of the three secrets: `secret1`, `secret2`, and `secret3` using only what is available to the restricted user.
- Switch back to the kubernetes-admin context when finished with `kubectl config use-context kubernetes-admin@kubernetes`

🧰 Context:

- Namespace `team-red` contains 3 pods: `pod1`, `pod2`, and `pod3`.
- The user restricted has no permission to `list`, `get`, or describe Secrets or RBAC objects.
- Secrets are used by the Pods in creative ways: via mounted volumes, environment variables, or API calls via their service account tokens.

✅ Expected result:

You were able to extract and decode all 3 secrets despite the lack of direct access.

🧹 A reset.sh script is available to clean the cluster between attempts.