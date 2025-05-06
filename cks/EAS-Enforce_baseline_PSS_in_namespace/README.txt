🛡️ Lab: Enforce baseline Pod Security Standard in a Namespace

🧠 Difficulty: Easy  
🧩 Domain: Cluster Hardening  
⏱️ Estimated Time: 10 minutes  

🎯 Goal:  
Restrict the ability for Pods to perform potentially dangerous operations by enforcing the **baseline** Pod Security Standard (PSS) on a Namespace.

📌 Your mission:  
1. Inspect the existing configuration of the `team-blue` Namespace.  
2. Modify the Namespace to **enforce** the `baseline` level of the Pod Security Standard.  
3. Delete the running Pod from the `hostile-container` Deployment in the same Namespace.  
4. Check the events of the Deployment to understand why the Pod is no longer recreated.

🧰 Context:  
- A Namespace `team-blue` is already created.  
- A Deployment named `hostile-container` exists and runs a Pod mounting a `hostPath` volume on `/run/containerd`, which can compromise other containers on the node.

✅ Expected result:  
- The Pod should not be able to restart due to a policy violation.  
- The Deployment should show a warning event with a message related to PodSecurity violation.

🧹 A `reset.sh` script is available to clean the cluster between attempts.
