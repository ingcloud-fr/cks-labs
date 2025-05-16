🛡️ Lab: Combine L3/L4 rules and mutual auth in Cilium

🧠 Difficulty: Advanced  
🧩 Domain: Minimize Microservice Vulnerabilities  
⏱️ Estimated Time: 20–30 minutes  

🎯 Objective:
You will create advanced CiliumNetworkPolicies to combine Layer 3 and Layer 4 restrictions with mutual authentication in `team-blue` namespace.

📌 Your Tasks:

1. Create a Layer 3 egress deny policy named `deny-egress-b-to-a`  
   → Deny all **egress traffic** from B to A

2. Create a Layer 4 deny policy named `deny-icmp-c-to-a`  
   → Deny outgoing **ICMP traffic** from C to A

3. Create a Layer 3 ingress policy with mutual authentication named `require-mtls-a-to-c`  
   → Allow outgoing traffic from A to C **only if mutual authentication is enforced**

🧰 Context:

- A namespace team-blue is already created
- The namespace contains:
  - A Deployment app-a with label app-a
  - A Deployment app-b with label app-b
  - A Deployment app-c with label app-c
- Each deployment has a service (service-a, service-b, etc)
- A `default-allow` CiliumNetworkPolicy is already in place and **must not be changed**
- All Pods run the image `wbitt/network-multitool`, exposing port 80

✅ Expected Result:

- Pods role=app-b **cannot reach** the service-a
- Pods role=app-c cannot send **ICMP (ping)** traffic to pods role=app-a
- Pods role=app-a can reach pods role=app-c **only** if mutual authentication succeeds
- Other allowed traffic (DNS, intra-namespace HTTP) must continue to work
- You can test connectivity using curl and ping from inside the namespace

🧹 A reset.sh script is available to clean the cluster between attempts.
