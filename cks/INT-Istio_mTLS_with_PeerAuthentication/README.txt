🛡️  Lab: Enable mTLS with Istio PeerAuthentication

🧠 Difficulty: Intermediate  
⏱️ Estimated Time: 10 minutes  
🧩 Domain: Minimize Microservice Vulnerabilities

🎯 Goal:  
Enable mutual TLS (mTLS) authentication between microservices using Istio by configuring PeerAuthentication.

📌 Your mission:

1. Label the namespace `team-app` to enable automatic sidecar injection.
2. Redeploy three deployments in this namespace:
   - `httpbin` as a test service (listens on port 8080)
   - `client` as a client (with sidecar) used to curl `httpbin-svc`
   - `naked` as a client (without sidecar) to simulate a failing call
3. Create a `PeerAuthentication` policy named `mutual-tls-auth` to require `STRICT` mTLS in the namespace `team-app`.
4. Verify that:
   - Requests from `sleep` to `httpbin` succeed ✅
   - Requests from `naked` to `httpbin` fail ❌

🧰 Context
- ✅ Istio is **already installed**.
- ✅ The namespace `team-app` already exists.
- ✅ Three pods are pre-deployed in the `team-app` namespace:
  - `httpbin`: a basic web server that listens on port 8080 with service `httpbin-svc`
  - `client`: a pod with sidecar, used to send HTTP requests to `httpbin`
  - `naked`: a pod **without the Istio sidecar**, used to test failure scenarios
- ✅ You can test on /env endpoint : `http://httpbin-svc:8080/env`
- 📁 The manifests used are stored in `~/manifests/` if you need to redeploy manually.


✅ Expected:
- mTLS is enforced between Pods via Istio sidecars.
- Only Pods with the sidecar proxy (`istio-proxy`) can communicate with `httpbin`.


| Source Pod | Has Sidecar | Can Call `httpbin`? |
|------------|-------------|---------------------|
| `client`   | ✅           | ✅ Yes             |
| `naked`    | ❌           | ❌ No              |


🧹 A `reset.sh` script is provided to clean up the namespace and Istio components.
