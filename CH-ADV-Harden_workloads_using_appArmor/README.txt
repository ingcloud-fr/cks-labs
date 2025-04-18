🛡️ Lab: Harden Workloads Using AppArmor

🧠 Difficulty: Advanced  
⏱️ Estimated Time: 20 minutes

🎯 Goal:
Use AppArmor to restrict the behavior of running containers in a Kubernetes cluster.

📌 Your mission:
1. Connect to the worker node named `k8s-node01` using SSH:
   ssh k8s-node01

2. Install AppArmor if not already installed.
   You can refer to the official documentation: https://gitlab.com/apparmor/apparmor/-/wikis/Documentation
   (Hint: You may need to install `apparmor` and `apparmor-utils`)

3. Load the AppArmor profile located at:
   /home/vagrant/apparmor/sec-profile

4. Label the node `k8s-node01` with:
   apparmor/enabled=true

5. Create a Deployment named `secure-nginx` in the `default` namespace with:
   - 1 replica
   - Image: nginx:1.27.1
   - A nodeSelector to schedule the Pod only on nodes labeled `apparmor/enabled=true`
   - AppArmor must be activated for the container

   (⚠️ Note: You are NOT told the AppArmor profile name — read the file yourself to determine it)

6. A second Deployment named `app-pair` has already been applied in the cluster.
   It contains **two containers**.  
   Update this Deployment to activate the AppArmor profile on **only one** of the containers.

7. Check the logs of the pods for any error or access denial caused by the profile (e.g., denied write to `/tmp`).

8. Finally, **remove the AppArmor label** from the node `k8s-node01` and the AppArmor profile/

🧰 Context:
- A profile file is available on the node at `/home/vagrant/apparmor/sec-profile`
- A Deployment named `app-pair` is already deployed with two containers
- You may modify the existing deployment using `kubectl edit` or by patching it

✅ Expected result:
- The profile is loaded and enforced on the node
- The `secure-nginx` Pod runs with AppArmor enabled
- The `app-pair` Deployment has one container protected with AppArmor
- If the protected container tries to write to `/tmp`, it should fail (check logs)

🧹 A `reset.sh` script is available to clean the cluster between attempts.
