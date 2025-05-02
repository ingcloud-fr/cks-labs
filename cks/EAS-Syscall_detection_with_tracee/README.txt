🛡️ Lab: Detecting a Pod Performing Unauthorized System Calls (Syscalls)

🧠 Difficulty: Easy  
⏱️ Estimated Time: 10–15 minutes

🎯 Goal:  
One of the deployed pods performs unauthorized (and potentially malicious) system calls.

📌 Your mission:
1. Install Tracee from AquaSecurity with `helm` in the namespace `tracee` : https://aquasecurity.github.io/tracee/latest/docs/install/kubernetes/
2. Make sure that Tracee use hostPID=true.
3. Identify the malicious pod using the detection tool installed automatically (Tracee).
4. Observe the suspicious syscalls in the Tracee's logs.
5. Scale the corresponding deployment to 0 to neutralize the threat.

🧰 Context:
- Three namespaces are created: `team-green`, `team-blue`, `team-red`.
- Only one pod performs forbidden syscalls (e.g., `mount`).
- The other pods are healthy and should not be affected.

✅ Expected result:
- The offending deployment is scaled to 0.

🧹 A `reset.sh` script is available to clean the cluster between attempts.