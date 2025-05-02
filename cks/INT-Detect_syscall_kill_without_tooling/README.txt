🛡️ Lab: Detect Syscall Kill Without Tooling

🧠 Difficulty: Intermediate  
⏱️ Estimated Time: 15 minutes

🎯 Goal:  
You must investigate a potential security issue manually by inspecting processes on the nodes. No tools like Falco or Tracee are available — this is a low-level investigation.

📌 Your mission:

1. A namespace `production` contains multiple Deployments with Pods spread over 2 nodes.
2. One of the applications is executing a forbidden syscall (`kill`) periodically.
3. Your task is to detect which Deployment is involved and scale it down to zero replicas.

🔍 Investigation hints:
- SSH into the nodes to inspect processes (`ps`, `strace`, etc.)
- Use `crictl` to inspect Pod and container information.
- Use `kubectl get pods -owide` to see which Pods run on which node.
- All Pods are running a binary named `app`.

✅ Expected:
- You correctly identify the Deployment executing the `kill` syscall.
- You scale the Deployment down to zero (`kubectl scale ... --replicas=0`).
- All other Deployments remain unaffected.

📎 Notes:
- No security monitoring tool is installed.
- Only one Deployment exhibits the forbidden behavior.
- The node name prefix may differ depending on your environment.

🧹 A `reset.sh` script is provided to clean up all resources.
