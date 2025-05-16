## Solution: Secure Docker Daemon with TLS and Custom Interface

### 1. 🔍 Initial State Verification 

Before applying the secure configuration, verify the current insecure setup:


Let's check if Docker listens on insecure ports :

```
$ sudo lsof -i | grep  docker
dockerd   19681            root    4u  IPv6 1208083      0t0  TCP *:2375 (LISTEN)

$ sudo ss -lntp | grep dockerd
LISTEN 0      4096               *:2375             *:*    users:(("dockerd",pid=9887,fd=4)) 
```

So docker is listening on the unsecure interface on port 2375.

To help, search for *tls* in docker's documentation : https://docs.docker.com/engine/security/protect-access/

You will find at the end (helps to remember the options)

```
Daemon modes
- tlsverify, tlscacert, tlscert, tlskey set: Authenticate clients
- tls, tlscert, tlskey: Do not authenticate clients
```

- Note : For TLS without authentication use *tls*, *tlscert*, *tlskey* and set *tlsverify* to **false** !

We try connecting without TLS :

```
$ curl http://localhost:2375/version | jq
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   824  100   824    0     0  60322      0 --:--:-- --:--:-- --:--:-- 63384
{
  "Platform": {
    "Name": "Docker Engine - Community"
  },
  "Components": [
    {
      "Name": "Engine",
      "Version": "28.1.1",
      "Details": {
        "ApiVersion": "1.49",
        "Arch": "amd64",
        "BuildTime": "2025-04-18T09:52:10.000000000+00:00",
        "Experimental": "false",
        "GitCommit": "01f442b",
        "GoVersion": "go1.23.8",
        "KernelVersion": "5.15.0-138-generic",
        "MinAPIVersion": "1.24",
        "Os": "linux"
      }
 ....
```

You can connect over HTTP without authentication — insecure setup !

We can even run an insecured image :

```bash
$ docker -H tcp://k8s-controlplane01:2375 build -t testimage -<<EOF
FROM alpine
CMD ["sh", "-c", "echo 'Hello from insecure build'; sleep 3600"]
EOF
```

And :

```
$ docker -H tcp://k8s-controlplane01:2375 image ls
REPOSITORY   TAG       IMAGE ID       CREATED        SIZE
testimage    latest    12acdedfbe0b   2 months ago   7.83MB

$ docker -H tcp://k8s-controlplane01:2375 run testimage
Hello from insecure build
```

And we can see it, the docker daemon configuration file `/etc/docker/daemon.json` :

```
$ sudo cat /etc/docker/daemon.json
{
  "hosts": ["unix:///var/run/docker.sock", "tcp://0.0.0.0:2375"]
}
```

### 2. 🔐 Activate TLS (without authentication)

Make sure the directory `/etc/docker/certs/` contains all necessary certs :

```
$ ls  /etc/docker/certs/
ca-key.pem  ca.pem  cert.pem  key.pem
```

First, we have to set up TLS only (no authentification) on the secure port (2376)

We edit `/etc/docker/daemon.json`:

```json
{
  "hosts": ["unix:///var/run/docker.sock", "tcp://0.0.0.0:2376"],
  "tls": true,                           
  "tlscert": "/etc/docker/certs/cert.pem", 
  "tlskey": "/etc/docker/certs/key.pem",   
  "tlsverify": false
}
```

Why `"tlsverify": false` ?

According to the knowledge sources, starting with Docker v27.0, if you configure the daemon to listen on a TCP address (other than tcp://localhost), **TLS verification (i.e., client authentication) is mandatory**. The daemon will fail to start if you set `"tls": true` without "tlsverify": true for remote TCP connections. This means that, for most remote access scenarios, you cannot use TLS without client authentication anymore. **This mode is deprecated and will be removed in v28.0**. For more details, see Unauthenticated TCP connections.
If you only bind to `tcp://localhost`, you may still be able to use TLS without client authentication, but **this is not recommended for production or remote access**.


We restart Docker:

```bash
sudo systemctl daemon-reexec
sudo systemctl restart docker
```
Verify Docker now listens on **secured port 2376** only:

```bash
$ sudo ss -lntp | grep dockerd
LISTEN 0      4096               *:2376             *:*    users:(("dockerd",pid=10637,fd=4))
```

Or : 

```bash
$ ss -tuln | grep 2375
$ 
$ ss -tuln | grep 2376
tcp   LISTEN 0      4096
```

Or :

```bash
$ sudo lsof -i | grep docker
dockerd   20872            root    4u  IPv6 1248065      0t0  TCP *:2376 (LISTEN)
```

We see port 2376, not 2375.

Now we try a https connection :

```
$ curl -k https://localhost:2376/version | jq
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   824  100   824    0     0  26915      0 --:--:-- --:--:-- --:--:-- 28413
{
  "Platform": {
    "Name": "Docker Engine - Community"
  },
  "Components": [
    {
      "Name": "Engine",
      "Version": "28.1.1",
      "Details": {
        "ApiVersion": "1.49",
```

Ok we have activated TLS !

### 3. Activate TLS with mutual authentication (mTLS)

We edit `/etc/docker/daemon.json` again, we modify `tlsverify` and add `tlscacert` :

```json
{
  "hosts": ["unix:///var/run/docker.sock", "tcp://0.0.0.0:2376"],
  "tls": true,                             
  "tlscert": "/etc/docker/certs/cert.pem", 
  "tlskey": "/etc/docker/certs/key.pem",   
  "tlsverify": true,                      
  "tlscacert": "/etc/docker/certs/ca.pem", 
}
```

We reload Docker:

```bash
sudo systemctl daemon-reexec
sudo systemctl restart docker
```

Ok we try a TLS connection without authentificatiob :

```
$ curl -k https://localhost:2376/version 
curl: (56) OpenSSL SSL_read: error:0A00045C:SSL routines::tlsv13 alert certificate required, errno 0
```

Now Docker asks for authentication !

If we want to test the Docker mTLS connection (mutaul authentification), the client must have its own certificats to connect to Docker.

Just do some theory !

#### Overview of Required PKI Files for mTLS

| File Name      | Purpose                                      | Used By         | Shared With        |
|----------------|----------------------------------------------|------------------|--------------------|
| `ca.pem`       | Certificate Authority (CA) cert               | Both (Trust Root) | Shared by client & server |
| `ca-key.pem`   | Certificate Authority (CA) private key        | CA only          | 🔒 Must be kept secret |
| `cert.pem`     | TLS certificate for Docker **daemon**         | Server           |                     |
| `key.pem`      | Private key for Docker **daemon**             | Server           | 🔒 Must be kept secret |
| `client-cert.pem` | TLS certificate for **client**               | Client           |                     |
| `client-key.pem`  | Private key for **client**                   | Client           | 🔒 Must be kept secret |



          🔐 Authority (CA)
              ├── ca.pem       (public, common)
              ├── ca-key.pem   (private)

       ┌────────────┐                     ┌────────────┐
       │  Server    │                     │  Client    │
       ├────────────┤                     ├────────────┤
       │ cert.pem   │ ◄── signed par CA ─ │            │
       │ key.pem    │                     │            │
       │ ca.pem     │ ── checks  ───────► │ cert.pem   │
       └────────────┘                     │ key.pem    │
                                          │ ca.pem     │
                                          └────────────┘


#### Purpose of Each File

- `ca.pem`:
  - Public certificate of the Certificate Authority
  - Trusted by **both Docker daemon and client**
  - Used to verify identities

- `ca-key.pem`:
  - Private key used to sign server and client certs
  - Should remain private and offline if possible

- `cert.pem` & `key.pem`:
  - The Docker daemon's TLS cert and key
  - Used to identify and secure the server

- `client-cert.pem` & `client-key.pem`:
  - Used by clients (like `docker` CLI or remote tooling) to authenticate to the Docker daemon


#### 🛠️ How to Generate Client Certificates

We already have a CA (`ca.pem` and `ca-key.pem` in `/etc/docker/certs/` ), here's how to generate the client certificate:

- Note: the entire process is in docker documentation https://docs.docker.com/engine/security/protect-access/ 

- Step 1: Create a private key for the client

```
$ openssl genrsa -out client-key.pem 4096
```

- Step 2: Create a certificate signing request (CSR)
```
$ openssl req -new -key client-key.pem -out client.csr -subj "/CN=docker-client"
```

- Step 3: Create a configuration file for client auth

```
$ cat > client-ext.cnf <<EOF
extendedKeyUsage = clientAuth
EOF
```

- Step 4: Sign the CSR using the key and the CA :

```
$ sudo openssl x509 -req -in client.csr -CA /etc/docker/certs/ca.pem -CAkey /etc/docker/certs/ca-key.pem \
    -CAcreateserial -out client-cert.pem -days 365 -extfile client-ext.cnf
Certificate request self-signature ok
subject=CN = docker-client
```

We do not need these files anymore :

```
$ rm client.csr client-ext.cnf
```

Your client now has:
- `client-cert.pem`: the signed certificate (by the CA)
- `client-key.pem`: the private key

You can test it using:

```
$ sudo docker --tlsverify \
    --tlscacert=/etc/docker/certs/ca.pem \
    --tlscert=client-cert.pem \
    --tlskey=client-key.pem \
    -H tcp://localhost:2376 info
```

The response is :

```
$ sudo docker --tlsverify --tlscacert=/etc/docker/certs/ca.pem --tlscert=client-cert.pem \
  --tlskey=client-key.pem -H tcp://localhost:2376 info
  
Client: Docker Engine - Community
 Version:    28.1.1
 Context:    default
 Debug Mode: false
 Plugins:
  buildx: Docker Buildx (Docker Inc.)
    Version:  v0.23.0
    Path:     /usr/libexec/docker/cli-plugins/docker-buildx
...
```

Ok now we have mutual TLS authentification !

## Notes on Docker with systemd

Ubuntu runs Docker with *systemd* and pass the configuration in `/lib/systemd/system/docker.service`. In this lab, in order to explore `daemon.json` configuration file, we had to modify in `/lib/systemd/system/docker.service` in `deploy.sh` because configuring Docker to listen for connections using both the systemd unit file and the `daemon.json` file causes a conflict that prevents Docker from starting.

We change :

```
[Service]
...
ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
```

To :

```
[Service]
...
ExecStart=/usr/bin/dockerd --containerd=/run/containerd/containerd.sock
```

- Doc : https://docs.docker.com/engine/daemon/remote-access/#configuring-remote-access-with-systemd-unit-file 


### What is `-H fd://`?

The Docker daemon (`dockerd`) supports specifying the host(s) it should listen on via the `-H` flag. The default on systemd-based systems is:

```bash
ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
```

The `-H fd://` tells Docker to use a **file descriptor** passed by **systemd**, specifically the one managed by the `docker.socket` unit. It is a systemd feature used for socket activation.

### What is the service `docker.socket`?

Systemd provides a `docker.socket` unit which listens on the default UNIX socket (`/run/docker.sock`). When a client sends a connection request to that socket, systemd starts the Docker daemon (`dockerd`) and passes the open socket file descriptor.

You can check it via:

```bash
$ sudo systemctl cat docker.socket
# /lib/systemd/system/docker.socket
[Unit]
Description=Docker Socket for the API

[Socket]
# If /var/run is not implemented as a symlink to /run, you may need to
# specify ListenStream=/var/run/docker.sock instead.
ListenStream=/run/docker.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker

[Install]
WantedBy=sockets.target
```

It listens on:
```
/run/docker.sock
```

### 3. Interaction with `docker.service`

The `docker.service` file contains:

```ini
ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
```

This tells Docker to use the file descriptor passed by `docker.socket` (hence `fd://`) and to use the containerd socket explicitly.

### What are `/run/docker.sock` and `/var/run/docker.sock`?

On modern Linux systems:
- `/run` is a **tmpfs**, mounted at boot and used for runtime files.
- `/var/run` is **usually a symbolic link** to `/run`.

You can confirm with:

```bash
ls -ld /var/run
```

If `/var/run` → `/run`, then `/var/run/docker.sock` and `/run/docker.sock` are **exactly the same file** (same inode, same socket).

You can verify with:

```bash
$ stat /run/docker.sock
  File: /run/docker.sock
  Size: 0         	Blocks: 0          IO Block: 4096   socket
Device: 18h/24d	Inode: 8513        Links: 1
...

$ stat /var/run/docker.sock
  File: /var/run/docker.sock
  Size: 0         	Blocks: 0          IO Block: 4096   socket
Device: 18h/24d	Inode: 8513        Links: 1
...
```

Same inode (`8513`) = same file.

### How about `/run/containerd/containerd.sock`?

This is the UNIX socket used by Docker to communicate with **containerd**, the container runtime it relies on. It is unrelated to the Docker client interface but necessary for container lifecycle operations.

### Why is this important?

When using `-H fd://`, **you must not also specify another `-H` directive in `daemon.json`**. Doing so causes a conflict:

```
error: the following directives are specified both as a flag and in the configuration file: hosts
```

If you want to switch to a custom `daemon.json`, you should **remove `-H fd://` from the service file** and handle all `hosts` entries in the config file.

### Summary of Socket Locations
| Path                       | Purpose                                  |
|---------------------------|-------------------------------------------|
| `/run/docker.sock`        | Default Docker UNIX socket               |
| `/var/run/docker.sock`    | Alias to `/run/docker.sock`              |
| `/run/containerd/containerd.sock` | Docker → containerd communication |

### Final Notes
- Avoid duplicate host definitions (`-H`) in CLI and `daemon.json`
- Use `docker.socket` with `-H fd://` only if relying on systemd socket activation
- For custom TCP setup (e.g., port 2375 or 2376), create `/etc/docker/daemon.json` and adjust `docker.service` accordingly

---
This information is essential for securing and troubleshooting Docker socket access and remote API exposure.

The `reset.sh` script restores the genuine configuration.

## 🛡️ Best Practices

- Use a **different key pair** for client and server
- Keep `*-key.pem` files private and protected
- Avoid using `ca-key.pem` outside of your cert generation machine
- Use short-lived client certs and rotate regularly

---

## 📚 References
- Docker TLS: https://docs.docker.com/engine/security/https/
- Docker official TLS config: https://docs.docker.com/engine/security/protect-access/
- Hardening guide: https://docs.docker.com/engine/security/
- OpenSSL for creating certs: https://www.openssl.org/
- TLS in production: https://smallstep.com/blog/build-a-tls-pki/

