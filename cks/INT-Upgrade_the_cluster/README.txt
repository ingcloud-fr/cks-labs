🧪 Lab: Upgrade Kubernetes Cluster to v1.33

🧠 Difficulty: Intermediate  
⏱️  Estimated Time: 15 minutes

🎯 Objective:
Practice upgrading a Kubernetes cluster from version 1.32 to 1.33 with `kubeadm` in a controlled lab environment.

⚠️ Prerequisites:
- The cluster use kubeadm
- This lab assumes your cluster is currently running Kubernetes version **v1.32**.
- If you used `vcluster` to create this environment, make sure it was launched with `K8S_VERSION=1.32` or `./vcluster up -n k8s -v 1.32`
- For training, you can also have 2 controlplanes with : `./vcluster up -n k8s -v 1.32`

📌 Goals:
- Understand the upgrade steps and their impact.
- Prepare the control plane and nodes for upgrade.
- Perform the upgrade using official tools.
- Keep critical workloads running during the upgrade process.

🚨 Application to Protect:
- A sample **nginx Deployment** (2 replicas) will be running in the `team-green` namespace.
- This deployment **must remain available** during the entire upgrade procedure.
- It simulates a production workload that must not be interrupted.

✅ Success Criteria:
- The cluster successfully runs Kubernetes version **v1.33** after the upgrade.
- All nodes are in `Ready` state.
- The `nginx` deployment remains up and available during the upgrade.
- No pods are restarted or terminated unexpectedly.

💡 Tip:
This lab is designed for **learning purposes only**. Do not replicate in production without proper testing and backup procedures.
