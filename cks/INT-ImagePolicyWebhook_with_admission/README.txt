🔐 Lab: Enforce ImagePolicyWebhook using a Webhook Server

🧠 Difficulty: Intermediate  
⏱️ Estimated Time: 15 minutes

🎯 Goal:  
Create and activate an `ImagePolicyWebhook` configuration that uses an external admission webhook to validate container images.

📌 Your mission:
1. Create an `ImagePolicyWebhook` configuration in `/etc/kubernetes/security/webhook/` that uses the webhook server deployed in the `webhook-system` namespace.
2. Set the following policy values:
   - `allowTTL: 100`
   - `denyTTL: 100`
   - `retryBackoff: 500`
   - `defaultAllow: false` (fail closed)
3. Modify the `kube-apiserver` configuration so it loads your ImagePolicyWebhook settings.
4. Restart the `kube-apiserver` to apply the changes.
5. Test your setup by attempting to deploy a Pod using the `busybox` image (should be denied), and another with a different image like `nginx` (should be allowed).

🧰 Context:
- A running webhook server is already deployed under the service name `webhook-service.webhook-system.svc`.
- Its kubeconfig file is located at `/etc/kubernetes/security/webhook/webhook-kubeconfig.yaml`.
- For your information, the lab creates a key/cert for the Webhook server, they are in /tmp (educ purpose)
- A backup of the `kube-apiserver.yaml` is located in `/tmp`

✅ Expected result:
- The busybox image is rejected at admission.
- Another image (e.g., `nginx`) is accepted.
- In case of webhook failure, all images are denied (fail-closed policy).

🧹 A `reset.sh` script is available to restore the cluster configuration.
