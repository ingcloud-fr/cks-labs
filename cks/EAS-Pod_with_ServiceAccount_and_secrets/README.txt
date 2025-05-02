🔐 Lab: Pod with ServiceAccount and Mounted Secrets

🧠 Difficulty: Easy  
⏱️ Estimated Time: 10 minutes

🎯 Goal:  
Create a Pod that uses a custom ServiceAccount and consumes Kubernetes Secrets via environment variables and volume mounts.

📌 Your mission:


1. Create a ServiceAccount named `secret-sa` in the namespace `team-red`
2. Create a Secret named `secret-1` containing:
   - key: password
   - value: 1234
3. Create another Secret named `secret-2` from a file (e.g. `/etc/hosts`)
4. Create a Pod named `secret-manager` using image `nginx`, which:
   - uses the `secret-sa` ServiceAccount
   - injects `secret-1` as an environment variable named `SECRET1`
   - mounts `secret-2` as a read-only volume at `/etc/my-secret2`

✅ Expected:
- Inside the Pod, the env var `SECRET1` should be set to `1234`
- The file from `secret-2` should be accessible under `/etc/my-secret2/hosts`

🧹 A `reset.sh` script is provided to clean up the namespace and its resources.
