🛡️ Lab: Limit Capabilities for a Microservice

🧠 Difficulty: Intermediate  
⏱️ Estimated Time: 10 minutes

🎯 Goal:  
Minimize the Linux capabilities available to a container, following the principle of least privilege.

📌 Your mission:

1. In the namespace `team-blue`, a pod named `webapp` is defined in `/home/vagrant/manifests/webapp.yaml`.
   - It uses an image that starts a Python HTTP server on port 80
   - The current configuration **fails to start** because the container lacks the required Linux capability

2. Your task is to modify the pod manifest to:
   - Drop **all** capabilities (`capabilities.drop: ["ALL"]`)
   - Add only `NET_BIND_SERVICE` (`capabilities.add: ["NET_BIND_SERVICE"]`)
   - Run as `root` (user ID 0), because binding to port 80 requires either root or a binary pre-equipped with the right capability (not covered here)

✅ Expected:
- After applying the correct configuration, the pod starts successfully
- You can access the Python web server on port 80 using:

$ kubectl port-forward -n team-blue pod/webapp 8080:80 curl http://localhost:8080


🔄 Bonus (optional):
- Try adjusting the Pod to run as a non-root user and serve on port 8080 instead. This avoids needing elevated privileges or added capabilities.

🧹 A `reset.sh` script is available to restore the lab environment.
