🛡️ Lab: Control Ingress and Egress Between Applications

🧠 Difficulty: Advanced  
⏱️ Estimated Time: 20 minutes

🎯 Goal:  
Enforce strict communication rules between frontend and backend applications using both ingress and egress Network Policies.

📌 Your mission:

In namespace `team-green`:

1. Two pods are deployed:
   - `frontend` with label `app=frontend`
   - `backend` with label `app=backend`

2. You must create two Network Policies:

🔒 A rule named `backend-policy`:
- Allow **only ingress** from pods with label `app=frontend` to backend on port 3000 only
- Block all other ingress traffic
- No egress rules needed (default allow)

🔒 A rule named `frontend-policy`:
- Allow **egress** from frontend to pods backend on port 3000
- Allow **egress** frontend DNS requests (UDP/53 and TCP/53) to namespace `kube-system`
- Block all other egress traffic (i.e. frontend can't access internet or other services)
- No ingress rules needed

✅ Expected:
- `frontend` can talk to `backend`
- `backend` cannot talk to `frontend` or anyone else
- `frontend` cannot access external services

🧹 A reset.sh script is provided to clean the lab resources.
