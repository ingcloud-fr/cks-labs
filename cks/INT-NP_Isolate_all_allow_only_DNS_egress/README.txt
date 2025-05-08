🛡️ Lab: Isolate All Egress Except DNS

🧠 Difficulty: Intermediate  
⏱️ Estimated Time: 10 minutes

🎯 Goal:  
You must restrict all egress traffic from pods in a namespace, **except DNS queries**.

📌 Your mission:

In the namespace `team-white`:

1. A pod named `dns-tester` (image: busybox) is deployed
2. You must create a NetworkPolicy that:
   - Denies all egress traffic by default
   - Only allows DNS traffic (UDP/TCP on port 53)
   - DNS traffic must go to the `kube-dns` pods in the `kube-system` namespace (label `k8s-app=kube-dns`)

✅ Expected:
- The pod can resolve DNS names (e.g. `nslookup google.com`)
- The pod cannot reach any other service or IP

🧪 Example test:

$ nslookup google.com             ✅
$ wget -q --timeout=2 google.com  ❌

🧹 A `reset.sh` script is provided to clean up the namespace and policy.