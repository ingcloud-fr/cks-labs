🔐 Lab: Read and Decode Kubernetes Secrets from ETCD

🧠 Difficulty: Advanced  
🧩 Domain: Cluster Hardening  
⏱️ Estimated Time: 20 minutes

🎯 Objective:  
In this lab, you will explore how Kubernetes Secrets and ConfigMaps are stored in etcd. You will inspect etcd directly, decode secret data, and finally enable encryption at rest for sensitive Kubernetes resources.

📌 Your Tasks:

1. Locate and extract the full content of the existing Secret `database-password` from etcd in the Namespace `team-blue`.  
   → Store the full raw etcd base64 value into `/opt/labs/etcd-secrets`

2. Decode the base64 content of the key `"pass"` from this Secret and save the result into:  
   → `/opt/labs/database-password`

3. Configure **encryption at rest** for Secret and ConfigMap resources:  
   → Use an AES-CBC key provider in an `EncryptionConfiguration` file  
   → Apply it and restart the kube-apiserver  
   → Create a new Secret and a ConfigMap and verify their data is now stored encrypted in etcd

🧰 Context:

- The cluster uses etcd as its key-value store and is accessible via `etcdctl`
- The Secret `database-password` already exists in Namespace `team-blue`
- You can use `/etc/kubernetes/pki/etcd/` for etcd certificates
- Encryption at rest is not enabled at the start of this lab

✅ Expected result:

- `/opt/labs/etcd-secrets` must contain the raw base64 value of the Secret from etcd
- `/opt/labs/database-password` must contain the decoded plain-text value
- The new Secret and ConfigMap created after encryption should appear encrypted in etcd (e.g., `k8s:enc:aescbc:v1:key1...` prefix)
- Older Secrets not re-encrypted will still appear in plain base64

📚 References:

- https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/
- https://etcd.io/docs/v3.5/op-guide/security/
