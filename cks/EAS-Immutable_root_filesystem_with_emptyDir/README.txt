🔐 Lab: Make the Root Filesystem of a Container Read-Only

🧠 Difficulty: Intermediate  
🧩 Domain: Minimize Microservice Vulnerabilities  
⏱️ Estimated Time: 10–15 minutes

🎯 Goal:  
Prevent an attacker from modifying the container’s root filesystem while still allowing write access to `/tmp`.

📌 Your mission:
1. A deployment already exists under the namespace `team-green`, defined in `~/manifests/deployment.yaml`.
2. Your task is to make the root filesystem read-only for the container.
3. However, the `/tmp` directory should still be writable.
4. You are **not allowed to change the Docker image**.

🧰 Context:
- The container uses the image `busybox:1.32.0` with a simple `tail -f /dev/null` command.
- The root filesystem is currently writeable.

✅ Expected result:
- Attempts to write to `/etc/`, `/var/` or `/` should fail.
- Writing to `/tmp` must still succeed.
- Save your updated manifest to `/opt/labs/deployment-new.yaml` and apply it.

🧹 A `reset.sh` script is available to clean the cluster between attempts.
