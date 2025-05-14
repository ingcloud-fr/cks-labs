🔐 Lab: Isolating a Pod Using gVisor RuntimeClass

🧠 Difficulty: Intermediate  
⏱️ Estimated Time: 10 minutes

🎯 Goal:  
Learn how to isolate container workloads using the gVisor runtime, integrated via `RuntimeClass` and containerd in Kubernetes.

📌 Your mission:
1. Create a RuntimeClass named `gvisor` using the proper handler value ('runsc').
2. Deploy a pod named `pod-gvisor` in the `team-red` namespace using the `ubuntu` image and specify the runtime `gvisor`.
3. Verify that the pod is scheduled correctly and running under the gVisor runtime.

🧰 Context:
- The `runsc` binary (gVisor runtime) is already installed on all nodes.
- The only remaining step is to define and register the `gvisor` runtime with containerd using the appropriate handler.
- This setup targets enhanced security and isolation using the gVisor user-space kernel.
- All changes apply cluster-wide and will be validated with a simple test pod.

✅ Expected result:
- The `pod-gvisor` should be running using the `gvisor` runtime.
- You should be able to confirm the runtime via `crictl inspect` or containerd debug info.
- The `RuntimeClass` should be properly mapped and accepted by the API server.

💡 Useful documentation:
- Gvisor installation: https://gvisor.dev/docs/user_guide/install/
- Containerd with Gvisor: https://gvisor.dev/docs/user_guide/containerd/quick_start/

🧹 A `reset.sh` script is available to clean the cluster between attempts.
