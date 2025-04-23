🛡️ Lab: kube-bench - Audit and Hardening of Kubernetes Components

🧠 Difficulty: Advanced
⏱️ Estimated Time: 30–45 minutes

🎯 Objective:
Use the kube-bench tool to detect and understand security misconfigurations across Kubernetes components, compare results before and after applying deploy.sh, and verify test behavior.

📌 Instructions:

1. Run kube-bench on the control-plane node.
   IMPORTANT: Always use the --version option to match your actual Kubernetes version.
   Example:
     kube-bench run --version 1.32

2. Focus on the following 15 tests. In the default cluster, 10 of them should FAIL.

Control Plane - Configuration Files:
- 1.1.11: Ensure etcd data directory permissions are set to 700 or more restrictive                       

Kube-apiserver:
- 1.2.6 : Ensure --authorization-mode is NOT set to AlwaysAllow                        
- 1.2.7 : Ensure --authorization-mode includes Node                                  
- 1.2.8 : Ensure --authorization-mode includes RBAC                                   
- 1.2.15: Ensure --profiling is set to false                                           
- 1.2.22: Ensure --service-account-key-file is set                                    
- 1.2.23: Ensure --etcd-certfile and --etcd-keyfile are configured                    
- 1.2.24: Ensure --tls-cert-file and --tls-private-key-file are configured             

Kube-controller-manager:
- 1.3.2: Ensure --profiling is set to false                                            

Kube-scheduler:
- 1.4.1: Ensure --profiling is set to false                                          

Etcd:
- 2.1: Ensure --cert-file and --key-file are configured                               
- 2.2: Ensure --client-cert-auth=true                                               

Kubelet:
- 4.2.1: Ensure --anonymous-auth=false                                                
- 4.2.2: Ensure --authorization-mode is not AlwaysAllow                           
- 4.2.11: Ensure RotateKubeletServerCertificate is set to true                  

📦 Notes:
- The kubelet configuration is managed via a ConfigMap (`kubelet-config`) in the kube-system namespace.
- To persist modifications across upgrades, you must:
    1. Patch the ConfigMap.
    2. Apply the changes with:
         sudo kubeadm upgrade node phase kubelet-config

🧠 Reminder:
Modifying `/var/lib/kubelet/config.yaml` directly is NOT persistent and will be overwritten after a kubeadm upgrade. You must always modify the ConfigMap instead.

📁 Resources:
- All manifests: /etc/kubernetes/manifests/
- Backup location: /etc/kubernetes/backup/
- kube-bench is installed by: tools/install-kube-bench.sh

✅ Goal:
- Correct the tests in FAIL state
- Re-run the kube-ben to check that all 16 tests are PASSed

🧹 A `reset.sh` script is available to clean the cluster
