⚙️ Lab: Update Kubelet Configuration with Kubeadm

🧠 Difficulty: Intermediate  
🧩 Domain: Cluster Setup  
⏱️ Estimated Time: 15–20 minutes  

🎯 Goal:  
You have to update the cluster's KubeletConfiguration. Implement the following changes in the **Kubeadm way** to ensure that **new nodes added to the cluster or during a cluster upgrade will receive the updated settings**.

📌 Your mission:  
- Set `containerLogMaxSize` to `5Mi`  
- Set `maxPods` to `50`  
- Set `seccompDefault` to `true` to enforce the `RuntimeDefault` seccomp profile by default on all Pods  
- Apply the changes for the Kubelet on both `controlplane01` and `node01`

🧰 Context:  
- The cluster was initialized using `kubeadm`  
- Each node uses its own kubelet config located at `/var/lib/kubelet/config.yaml`, dynamically generated based on the cluster's ConfigMap

✅ Expected result:  
- Both nodes reflect the new Kubelet configuration in `/var/lib/kubelet/config.yaml`  
- The updated values are visible via each node’s `/configz` endpoint  
- Launch a new Pod and verify that the `RuntimeDefault` seccomp profile is enforced (not so easy 😉)  
- Future nodes will automatically inherit the updated configuration

📚 References:  
- Reconfigure a cluster with kubeadm: https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-reconfigure/#applying-kubelet-configuration-changes  
- Kubelet Configuration API: https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/
