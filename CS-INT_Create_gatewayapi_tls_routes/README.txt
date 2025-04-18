🌉 Lab: Create a Gateway API TLS Route for Two Web Applications

🧠 Difficulty: Intermediate  
⏱️ Estimated Time: 20–25 minutes

🎯 Goal:  
Expose two web applications securely using Gateway API and TLS with distinct paths /pay and /shop.

📌 Your mission:
1. Generate a TLS certificate and private key for www.my-web-site.org using the provided openssl command.
2. Create a Kubernetes secret named secret-tls in the team-web namespace using the generated cert/key.
3. Create the necessary Gateway API resources:
   - A Gateway configured for HTTPS on port 443, using the default GatewayClass.
   - A HTTPRoute mapping /pay → backend, and /shop → frontend.
   - TLS must be enabled using the previously created secret-tls.

🧰 Context:
- A namespace team-web is created.
- Two simple nginx applications are deployed: backend, frontend.
- A Gateway API-compatible controller is installed (type NodePort).

ℹ️ Note:
The NGINX Gateway controller deployed by Helm automatically creates and accepts a GatewayClass named `nginx`, with the controller name:
  gateway.nginx.org/nginx-gateway-controller

You can verify this with:
  kubectl get gatewayclass

📦 TLS generation hint:
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=www.my-web-site.org/O=MyOrg"

✅ Expected result:
- HTTPS requests to /pay return the backend default page.
- HTTPS requests to /shop return the frontend default page.

📖 Reference: You may follow the official documentation for GatewayClass and Tls creation:
- https://kubernetes.io/docs/concepts/services-networking/gateway/
- https://gateway-api.sigs.k8s.io/guides/tls/


🧪 Tip:
You can use curl --resolve to simulate DNS resolution (or add the host in your /etc/hosts with the right IP):

curl -k --resolve www.my-web-site.org:<TLS_PORT>:<NODE_IP> https://www.my-web-site.org:<TLS_PORT>/pay
curl -k --resolve www.my-web-site.org:<TLS_PORT>:<NODE_IP> https://www.my-web-site.org:<TLS_PORT>/shop

🧹 A reset.sh script is available to clean the cluster between attempts.
