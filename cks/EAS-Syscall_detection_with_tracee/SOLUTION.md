# 🛡️ Lab: Detecting Syscalls with Tracee

🧠 Difficulty : Easy

⏱️ Estimated Time : 10 minutes

🎯 Goal : Learn how to detect syscall activity (e.g., `ptrace`, `exec`, etc.) in a Kubernetes cluster using **Tracee**, an eBPF-based runtime security tool.


## 🚀 Steps

### 1️⃣ Install Tracee

We install Tracee with *helm* following the documentation in the namespace `tracee` : https://aquasecurity.github.io/tracee/latest/docs/install/kubernetes/ :

```
$ helm repo add aqua https://aquasecurity.github.io/helm-charts/
$ helm repo update
$ helm install tracee aqua/tracee --namespace tracee --create-namespace
"aqua" has been added to your repositories
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "aqua" chart repository
...Successfully got an update from the "cilium" chart repository
Update Complete. ⎈Happy Helming!⎈
NAME: tracee
LAST DEPLOYED: Fri Apr 25 04:26:09 2025
NAMESPACE: tracee
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Tracee has been successfully installed as a set of pods scheduled on each Kubernetes cluster
node controlled by the `tracee` DaemonSet in the `tracee` namespace.
By default, threat detections are printed to the standard output of each pod:

$ kubectl logs -f daemonset/tracee -n tracee
```

We can check that Tracee has the `hostPID` option set to true :

```
$ helm -n tracee show values aqua/tracee | grep -i hostpid
# hostPID configures Tracee pods to use the host's pid namespace.
hostPID: true
```

- Note: For educ purpose, see below.

### 2️⃣ View Tracee Logs

Tracee runs as a DaemonSet, no need to install it on every node.
During the installation process, we can see how to get logs :

```
$ kubectl logs -f daemonset/tracee -n tracee | grep -i name
...
{"timestamp":1745555437776373143,"threadStartTime":1745555437776286850,"processorId":0,"processId":280,"cgroupId":15368,"threadId":280,"parentProcessId":278,"hostProcessId":44322,"hostThreadId":44322,"hostParentProcessId":44320,"userId":0,"mountNamespace":4026532490,"pidNamespace":4026532491,"processName":"strace","executable":{"path":""},"hostName":"app-c-8b9cd456c","containerId":"8498b67529680758f69b3a165b6ced82d90e7dae7c573dfa795a87925267230b","container":{"id":"8498b67529680758f69b3a165b6ced82d90e7dae7c573dfa795a87925267230b","name":"app","image":"docker.io/library/debian:bookworm-slim","imageDigest":"sha256:b1211f6d19afd012477bd34fdcabb6b663d680e0f4b0537da6e6b0fd057a3ec3"},"kubernetes":{"podName":"app-c-8b9cd456c-5h54z","podNamespace":"team-green","podUID":"7618a938-2586-486a-abaf-dd9a1b0c64d8"},"eventId":"6018","eventName":"anti_debugging","matchedPolicies":["default-policy"],"argsNum":1,"returnValue":0,"syscall":"ptrace","stackAddresses":null,"contextFlags":{"containerStarted":true,"isCompat":false},"threadEntityId":1747443885,"processEntityId":1747443885,"parentEntityId":3131917597,"args":[{"name":"triggeredBy","type":"unknown","value":{"args":[{"name":"request","type":"long","value":0},{"name":"pid","type":"pid_t","value":0},{"name":"addr","type":"void*","value":0},{"name":"data","type":"void*","value":0}],"id":101,"name":"ptrace","returnValue":0}}],"metadata":{"Version":"1","Description":"A process used anti-debugging techniques to block a debugger. Malware use anti-debugging to stay invisible and inhibit analysis of their behavior.","Tags":null,"Properties":{"Category":"defense-evasion","Kubernetes_Technique":"","Severity":1,"Technique":"Debugger Evasion","external_id":"T1622","id":"attack-pattern--e4dc8c01-417f-458d-9ee0-bb0617c1b391","signatureID":"TRC-102","signatureName":"Anti-Debugging detected"}}}
...
```

We can see :

- `podName":"app-c-8b9cd456c-5h54z","podNamespace":"team-green"`
- `"name":"ptrace"`

Tracee triggers the syscall `ptrace`, which is typically flagged as suspicious.
So we can guess the the `pod-c-8b9cd456c-5h54z` in the namespace team-green is using ptrace. Let'investigate :

### 3️⃣ Investigate 

```
$ k -n team-green describe pod/app-c-8b9cd456c-5h54z 
...
Controlled By:  ReplicaSet/app-c-8b9cd456c
...
    Command:
      sh
      -c
      apt update && apt install -y strace
      mkdir -p /mnt/test
      while true; do
        strace ls   
        sleep 10
      done
...
```

```
$ k -n team-green describe rs/app-c-8b9cd456c 
...
Controlled By:  Deployment/app-c

```

Ok, we have the deploment, we can scale it down to 0 :

```
$ k -n team-green scale deploy/app-c --replicas 0
deployment.apps/app-c scaled
```
## 🔐 Why Tracee Uses `hostPID: true`

You can verify this via:
```bash
helm show values aqua/tracee | grep -i hostPID
```

### 🧠 What is `hostPID`?

The field `hostPID: true` allows the container to share the **host’s process namespace**:
- It can see **all processes** running on the node.
- Without it, Tracee could only see processes inside its own Pod.

### ⚙️ Why is it required?
Tracee needs to:
- Monitor **all syscalls**, across containers and non-containerized workloads.
- Correlate events with **real host processes**.

So enabling `hostPID` is **essential** for a system-level observability tool like Tracee.

| ✅ Benefits                     | ⚠️ Risks                          |
|-------------------------------|-----------------------------------|
| Full visibility of the host   | Reduced container isolation       |
| Required for eBPF-based tools | Potential attack vector if misused |

## 📏 Best Practices for Tracee in Kubernetes

To get the most value and security out of Tracee, consider the following deployment best practices:

### 🧱 Isolation & Access Control
- **Dedicated Namespace**  
  Deploy Tracee in its own namespace (e.g., `tracee`) to isolate it from other workloads.

- **RBAC Rules**  
  Apply the principle of least privilege: Grant only the permissions required for Tracee to function (e.g., access to `/proc`, eBPF).

### 📆 Pod Scheduling & Placement
- **Tolerations & Node Affinity**  
  Use tolerations and affinity rules to ensure Tracee DaemonSet pods are scheduled **only on nodes** where they are needed, such as worker nodes running sensitive workloads.

### 🌐 Network Restrictions
- **NetworkPolicy**  
  Define `NetworkPolicy` to **block egress** by default. Only allow Tracee to send data to explicitly approved targets (e.g., Loki, volume, or external collector).

---

### 📤 Logging & Observability

#### 🔍 Basic Logging
- **Default Logging**  
  By default, Tracee logs detections to standard output (`kubectl logs` on the DaemonSet).

#### 📦 Enhanced Logging with Loki
To centralize and query detection logs:

- **Use Loki for Log Aggregation**  
  Loki is a log aggregation system designed to work like Prometheus but for logs. It’s efficient and integrates well with Grafana.

- **Use Promtail to Ship Logs**  
  Promtail collects Tracee logs from the nodes (or containers) and sends them to Loki.

- **Visualize in Grafana**  
  Grafana connects to Loki to **visualize** and **query** Tracee logs in real time.
  
  You can set up dashboards, define alerts, and filter by container, namespace, or event type.

#### 🧠 Example Architecture
```
[ Tracee (DaemonSet) ]
       |
    stdout
       |
[ Promtail ] --→ [ Loki ] ↔↔ [ Grafana ]
```

---

### 🔐 Integration with External SIEMs (Optional)
- **Forward to a SIEM (Security Information and Event Management)**  
  You can export logs from Loki or directly from Tracee to a **SIEM** (e.g., Splunk, ELK/Elastic, Wazuh) using log shippers or exporters.
  
  This enables:
  - Long-term forensic storage
  - Complex correlation rules
  - Alert workflows for SOC teams

