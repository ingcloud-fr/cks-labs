🔐 Lab: Isolating a Pod Using gVisor RuntimeClass

🧠 Difficulty: Intermediate  
⏱️ Estimated Time: 20–30 minutes

🎯 Goal:  
Learn how to isolate container workloads using the gVisor runtime, integrated via `RuntimeClass` and containerd in Kubernetes.

📌 Your mission:
1. Install gVisor (`runsc`) on all nodes using the official APT method.
2. Register the `runsc` runtime in containerd's configuration.
3. Deploy a RuntimeClass named `gvisor` using the proper handler.
4. Create a test pod that uses `runtimeClassName: gvisor` and verify it is running with the correct runtime.

🧰 Context:
- The gVisor sandbox runtime is used to improve container isolation.
- You will manually edit containerd's configuration to register the new runtime.
- This setup applies to all nodes in the cluster and is tested in the `team-red` namespace.

✅ Expected result:
- The test pod runs successfully using the gVisor runtime on the targeted node.
- The RuntimeClass is functional and mapped correctly to the containerd runtime.

💡 Useful documentation :
- Gvisor installation : https://gvisor.dev/docs/user_guide/install/
- Containerd with Gvisor : https://gvisor.dev/docs/user_guide/containerd/quick_start/

🧹 A `reset.sh` script is available to clean the cluster between attempts.