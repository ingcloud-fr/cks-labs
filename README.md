# 🛡️ Kubernetes Labs

- A series of labs to practice Kubernetes (CKS,etc).
- To be used with the Kubernetes cluster available here: https://github.com/ingcloud-fr/vagrant-virtualbox-kubernetes

## 🛠️ HowTo

Build a Kubernetes cluster :

```
$ git clone https://github.com/ingcloud-fr/vagrant-virtualbox-kubernetes.git
$ cd vagrant-virtualbox-kubernetes/build_image_jammy/
$ vagrant up
$ vagrant vagrant halt  
$ vagrant package --output jammy64-updated.box
$ vagrant box add jammy64-updated jammy64-updated.box 
```
Install a **v1.33** Kuberntes cluster (2 nodes) with *Virtuallbox* (need to be installed) in **Bridge static** mode from *192.168.1.200* (see `vcluster` to change default values) :

```
$ cd ..
$ ./vcluster up -n k8s
```

## 🧪 Install the labs 

Install the labs in the `vagrant-virtualbox-kubernetes` directory (normally, you are in)

```
$ git clone git@github.com:ingcloud-fr/kube-labs.git
```

Connect to the controlplane :

```
./vcluster ssh k8s-controlplane01
```
Go to the labs throught the shared directory `/vagrant` ::

```
$ cd /vagrant/kube-labs
```

And choose one and launch it :

```
$ cd CH-ADV-Fix_kube_bench_failures
$ ./deploy.sh
```

Notes : 
- The labs are formatted like this : LEVEL-Title_of_the_lab
- For the LEVEL : `BEG` for *Beginner*, `INT` for *Intermediate*, `ADV` for *Advanced*, `EXP` for *Expert*.

Do the labs and check the solution in `SOLUTION.md`

When you're done, do not forget to reset the lab environment :

```
$ ./reset.sh
```

Enjoy 🎮 !!


## 🧭 Certified Kubernetes Security Specialist (CKS) - Official Exam Topics

### 1. CS : Cluster Setup (10%)
- Use of secure container runtimes (e.g., containerd, CRI-O)
- Kubelet configuration (certificates, secure flags)
- Disable unused ports and services
- Secure CNI configuration and network boundaries

### 2. CH : Cluster Hardening (15%)
- Disable insecure ports on API Server and Kubelet
- Restrict Kubelet access and functionality
- Protect sensitive files and secrets (kubeconfig, etcd, etc.)
- Limit container capabilities (Linux capabilities, seccomp, etc.)

### 3. SH : System Hardening (15%)
- Harden host OS:
  - Firewall configuration (UFW, iptables)
  - AppArmor/SELinux setup
  - Kernel module restrictions
- Review and restrict file permissions
- Audit Docker or containerd configuration
- Remove unnecessary services and tools

### 4. MMV : Minimize Microservice Vulnerabilities (20%)
- Container image scanning (e.g., Trivy, Clair)
- Use of signed or trusted base images
- Enforce securityContext (readOnlyRootFilesystem, drop capabilities, etc.)
- Manage and protect Kubernetes Secrets securely

### 5. SCS : Supply Chain Security (20%)
- Image signing and verification (e.g., Cosign, Notary)
- Enforce policies using OPA Gatekeeper
- Use Admission Controllers (e.g., PodSecurity, ImagePolicyWebhook)
- Validate Kubernetes manifests for security compliance

### 6. MLR : Monitoring, Logging & Runtime Security (20%)
- Setup and configure tools like Falco, Auditd, Tracee
- Integrate with observability stack (Prometheus, Grafana, Loki)
- Detect suspicious activity (exec, privilege escalation, file writes, etc.)
- Analyze and audit cluster logs for security events

---

> This document outlines the official CKS exam curriculum maintained by the CNCF. Candidates should be familiar with both theoretical knowledge and hands-on application of these topics.
