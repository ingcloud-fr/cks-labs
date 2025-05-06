🌐 Lab: Allow ICMP and DNS with CiliumNetworkPolicy

🧠 Difficulty: Advanced  
🧩 Domain: Minimize Microservice Vulnerabilities  
⏱️ Estimated Time: 15–20 minutes

🎯 Goal:  
Create a `CiliumNetworkPolicy` that allows only DNS traffic and ICMP Echo Requests, and denies all other egress from a pod.

📌 Your mission:
1. Create a CiliumNetworkPolicy named `egress-allow-dns-icmp` that:
   - Allows egress DNS traffic (UDP port 53)
   - Allows ICMP echo requests (IPv4 type 8 and IPv6 EchoRequest)
   - Blocks all other egress traffic
2. Test the behavior using:
   - `dig` or `nslookup` to resolve DNS
   - `ping` to an external IP (e.g. `1.1.1.1`)
   - `curl` to external HTTP resources (should be denied)

🧰 Context:
- The pod `tester` is running a curl container for testing connectivity.
- No NetworkPolicy is applied at the start — full egress is allowed by default.

✅ Expected result:
- DNS and ICMP traffic should succeed.
- All other egress traffic should be dropped by the CNP.

🧹 A `reset.sh` script is available to clean the cluster between attempts.

📚 References:
- https://docs.cilium.io/en/stable/security/policy/language/#example-icmp-icmpv6
- https://docs.cilium.io/en/stable/security/policy/language/#dns-based


