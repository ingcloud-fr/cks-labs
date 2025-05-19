🛡️ Lab: Restrict DNS Resolution to Google Domains Only

🧠 Difficulty: Advanced  
🧩 Domain: Minimize Microservice Vulnerabilities  
⏱️ Estimated Time: 15–25 minutes

🎯 Goal:  
Limit the ability of Pods in a namespace to resolve DNS only for specific domains (`google.com` and `google.fr`) using a CiliumNetworkPolicy.

📌 Your mission:
1. Deploy a test Pod in namespace `team-purple`.
2. Apply a CiliumNetworkPolicy that restricts DNS queries to only:
   - `google.com` and its subdomains (www.google.com, api.google.com, etc)
3. Ensure that DNS queries for internal service in the cluster in any namespace are allowed (you can test with the service `nginx` in `team-green`)   
3. Ensure DNS queries for other domains (e.g. `bing.com`, `facebook.com`) are blocked.

🧰 Context:
- A namespace `team-purple` is created.
- A Pod named `tester` using the image `curlimages/curl` is deployed in `team-purple` namespace.
- A service is deployed in `team-green`.

✅ Expected result:
- `nslookup google.com` and `nslookup www.google.com` succeed from the test Pod.
- `nslookup nginx.team-green.svc.cluster.local` succeed from the test Pod.
- `nslookup bing.com` or any other domain fails with a timeout or NXDOMAIN.

🧹 A `reset.sh` script is available to clean the cluster between attempts.
