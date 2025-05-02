## ✅ Solution: Limit Capabilities for a Microservice

This solution demonstrates how to restrict Linux capabilities for a container, allowing it to run only with the minimum privileges required to bind to port 80.

---

### 🔍 Problem
The Pod runs a Python HTTP server on port 80. By default, binding to ports below 1024 requires elevated privileges (typically `root`) or the `NET_BIND_SERVICE` capability.

Initially, the Pod fails to bind to port 80 because it runs as a non-root user and does not have the necessary capabilities.

```
$ k -n team-blue get pod/webapp 
NAME     READY   STATUS   RESTARTS      AGE
webapp   0/1     Error    2 (23s ago)   45s


$ k -n team-blue logs pod/webapp 
Traceback (most recent call last):
  File "/usr/local/lib/python3.9/runpy.py", line 197, in _run_module_as_main
    return _run_code(code, main_globals, None,
  File "/usr/local/lib/python3.9/runpy.py", line 87, in _run_code
    exec(code, run_globals)
  File "/usr/local/lib/python3.9/http/server.py", line 1308, in <module>
    test(
  File "/usr/local/lib/python3.9/http/server.py", line 1259, in test
    with ServerClass(addr, HandlerClass) as httpd:
  File "/usr/local/lib/python3.9/socketserver.py", line 452, in __init__
    self.server_bind()
  File "/usr/local/lib/python3.9/http/server.py", line 1302, in server_bind
    return super().server_bind()
  File "/usr/local/lib/python3.9/http/server.py", line 137, in server_bind
    socketserver.TCPServer.server_bind(self)
  File "/usr/local/lib/python3.9/socketserver.py", line 466, in server_bind
    self.socket.bind(self.server_address)
PermissionError: [Errno 13] Permission denied

```

### ✅ Steps to Fix

You need to explicitly:
- Run as root
- Drop **all** Linux capabilities
- Add back only the `NET_BIND_SERVICE` capability

This adheres to the principle of least privilege.

However, binding to port 80 also requires root privileges **unless** the application binary itself has the capability set using tools like `setcap`. To keep the lab simple and focused on capabilities, we will run the container as `root`, but still demonstrate secure usage via capability restriction.

---

### 🛠 Correct Pod Configuration

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: webapp
  namespace: team-blue
  labels:
    app: webapp
spec:
  containers:
  - name: web
    image: python:3.9-slim
    command: ["python3", "-m", "http.server", "80"]
    ports:
    - containerPort: 80
    securityContext:
      runAsUser: 0
      capabilities:
        drop: ["ALL"]
        add: ["NET_BIND_SERVICE"]
```

---

### 🔍 Why `runAsUser: 1000` Fails

You may try the following configuration:

```yaml
securityContext:
  runAsUser: 1000
  capabilities:
    drop: ["ALL"]
    add: ["NET_BIND_SERVICE"]
```

However, **this still fails**, because:
- Even with the `NET_BIND_SERVICE` capability granted at the container level, the underlying binary (`python3`) must be executed with the appropriate privilege level.
- By default, Linux does not allow **non-root users** to inherit or make use of this capability unless it is assigned directly to the binary (e.g. via `setcap`).

Therefore, this configuration alone is not enough — you must either run as `root` **or** build a custom image that sets the capability on the Python binary.

---

### 🧪 Verification Steps

1. Apply the fixed manifest:

```bash
$ kubectl replace -f manifests/webapp.yaml
```

2. Wait for the pod to be `Running`:

```bash
$ k -n team-blue get pod/webapp
NAME     READY   STATUS    RESTARTS   AGE
webapp   1/1     Running   0          8s
```

3. Forward port 80 to your local machine:

```bash
$ kubectl port-forward -n team-blue pod/webapp 8080:80
```

4. In another terminal, test with `curl`:

```bash
$ curl http://localhost:8080
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Directory listing for /</title>
...
```

   ✅ You should see a directory listing or index page from the Python server.

---

### 🔄 Alternative: Use High Port with Non-Root User

Instead of modifying capabilities or using `setcap`, you can keep the `runAsUser: 1000` setting and simply bind to a high port (above 1024), such as:

```yaml
command: ["python3", "-m", "http.server", "8080"]
```

This avoids the need for any elevated privileges or special capabilities.

---

### ✅ Expected Outcome
- The Pod runs with a restricted capability set.
- All default Linux capabilities are dropped.
- The only added capability is `NET_BIND_SERVICE`, which is the **minimum required** to bind to port 80.
- The Python server is reachable on port 80 via port-forwarding.

This approach reduces the container's privileges while maintaining its functionality.

---

### 💡 Note
In a real-world scenario, it would be even better to:
- Run the container as a non-root user (`runAsUser: 1000` for example)
- And use tools like `setcap` at build time to grant the binary the `NET_BIND_SERVICE` capability

This requires a custom image and extra steps but offers stronger isolation.

#### 🛠 Example Dockerfile Using `setcap`

```Dockerfile
FROM python:3.9-slim

RUN apt-get update && \
    apt-get install -y libcap2-bin && \
    setcap 'cap_net_bind_service=+ep' /usr/local/bin/python3.9 && \
    apt-get remove --purge -y libcap2-bin && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

USER 1000
WORKDIR /app
CMD ["python3", "-m", "http.server", "80"]
```

We build the image :

```
$ docker build -t ingcloudfr/my-python:v1 .
```

We log in on Dockerhub :

```
$ docker login -u ingcloud
```

We push it on Dockerhub :

```
$ docker push ingcloudfr/my-python:v1
```

We edit webapp.yaml :

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: webapp
  namespace: team-blue
  labels:
    app: webapp
spec:
  nodeSelector:
    role: controlplane
  containers:
  - name: web
    image: ingcloudfr/my-python:v1 # CHANGE
    command: ["python3", "-m", "http.server", "80"]
    ports:
    - containerPort: 80
    securityContext:
      runAsUser: 1000
    #  capabilities:
    #    drop: ["ALL"]
    #    add: ["NET_BIND_SERVICE"]
```
```
$ k replace -f webapp.yaml --force
pod "webapp" deleted
pod/webapp replaced
```

In another terminal :

```
$ kubectl port-forward -n team-blue pod/webapp 8080:80
Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
```

```
$ curl http://localhost:8080
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Directory listing for /</title>
...
```

With this image, the pod can run as a non-root user and still bind to port 80 without adding capabilities at runtime.

