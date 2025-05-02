🔐 Lab: Secure Docker Daemon with TLS and Custom Interface

🧠 Difficulty: Intermediate  
⏱️ Estimated Time: 15 minutes

🎯 Goal:  
Harden the Docker daemon configuration on `controlplane01` by enabling remote access securely with TLS and disabling insecure interfaces.

📌 Your mission:
1. Check the current configuration
2. First, expose the Docker API remotely **only over TLS** (port 2376) and check.
3. Then, ensure mutual authentication with client certificates is enabled (`tlsverify`).
4. (Optional) Create client certificats and test the mutual authentication (use the docker documentation).

🧰 Context:
- The current Docker daemon `/etc/docker/certs/`is not secured and may accept connections on unsafe interfaces.
- TLS SERVER certificates are provided in `/etc/docker/certs/`:
  - `ca.pem`
  - `cert.pem`
  - `key.pem`

✅ Expected result:
- Docker must listen only on `tcp://0.0.0.0:2376` with TLS.
- Port 2375 must *NOT* be open or accessible.
- Docker must still be operational locally via `/var/run/docker.sock`.

🧹 A `reset.sh` script is available to restore the default configuration.
