🛡️ Lab: Mutating Pod Specs Using OPA Gatekeeper

🧠 Difficulty: Intermediate  
⏱️ Estimated Time: 20–30 minutes

🎯 Goal:  
Learn how to use OPA Gatekeeper's mutation capabilities to inject labels and securityContext defaults into Pods at creation time.

📌 Your mission:
1. Install OPA Gatekeeper using Helm in a namespace `gatekeeper-system` (Helm is already installed).
2. Create a mutation policy called 'mutation-label-admin-blue' that adds the label `admin=admin-blue` to any pod created in the namespace `team-blue`.
3. Create another mutation policy called 'add-seccomp-profile-in-pods-team-purple' that injects a seccomp profile type `RuntimeDefault` to all pods created in the namespace `team-purple`.
4. Verify that no mutations occur in the namespace `team-green`.
5. Remove OPA Gatekeeper

💡 Tips :

- You can use installation documentation : https://open-policy-agent.github.io/gatekeeper/website/docs/install
- You can use mutation examples : https://open-policy-agent.github.io/gatekeeper/website/docs/mutation

🧰 Context:
- Three namespaces are pre-created: `team-blue`, `team-green`, and `team-purple`.
- You are free to use any minimal Pod spec to test the behavior.
- Gatekeeper must be installed and configured by you using Helm.

✅ Expected result:
- A pod created in `team-blue` automatically receives the label `admin=admin-blue`.
- A pod created in `team-purple` has a `seccompProfile.type: RuntimeDefault` field in its securityContext.
- A pod created in `team-green` remains untouched.



🧹 A `reset.sh` script is available to clean the cluster between attempts.
