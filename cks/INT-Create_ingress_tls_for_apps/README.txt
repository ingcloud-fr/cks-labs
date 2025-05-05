🛡️ Lab: Create an Ingress with TLS for Two Applications

🧠 Difficulty: Intermediate  
⏱️ Estimated Time: 10-15 minutes

🎯 Goal:  
Expose two web apps securely using a TLS-enabled ingress with paths `/pay` and `/shop`.

📌 Your mission:
1. Generate a TLS certificate and private key for the domain `www.my-web-site.org` (127.0.0.1 in /etc/hosts).
   Example:
     openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
       -keyout tls.key -out tls.crt \
       -subj "/CN=www.my-web-site.org/O=MyOrg"
2. Create a secret named `secret-tls` in the `team-web` namespace using the generated cert/key.
3. Create an Ingress called `my-ingress-tls` that:
   - Uses the `nginx` ingress class.
   - Routes traffic to `/pay` → backend app, `/shop` → frontend app.
   - Uses TLS with `secret-tls` and host `www.my-web-site.org`.
   - Use rewrite annotation

🧰 Context:
- Two nginx apps are already deployed: `backend`, `frontend` in `team-web` namespace.
- They serve different pages via configMaps.
- A namespace `team-web` is created.
- An Ingress Class Controller is installed (class name `nginx`)

✅ Expected:
- Accessing https://www.my-web-site.org/pay returns “Backend Page”
- Accessing https://www.my-web-site.org/shop returns “Frontend Page”

🧪 Tip: 
- The line `127.0.0.1 www.my-web-site.org` is added to `/etc/hosts` (on both node).
- Use the PORT of ingress-nginx-controller service in ingress-nginx namespace (type Nodeport)
- Do not forget the rewrite annotation !

🧹 A `reset.sh` script is available to clean the cluster between attempts.
