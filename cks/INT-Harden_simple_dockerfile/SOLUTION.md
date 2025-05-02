## Solution: Harden a Python-based Docker Container


### The Dockerfle

Let's try to build and test the Dockerfile :

```
$ docker build -t app:v1 .
...
 1 warning found (use docker --debug to expand):
 - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ENV "SECRET") (line 5)

$ docker run app:v1 
🔐 The secret is: 2e064aad-3a90-4cde-ad86-16fad1f8943e
🕒 Sleeping for 3600 seconds to keep the container alive...
^C
```


### ✅ Key Improvements Explained

| Problem                         | Hardened Fix                                                                 |
|---------------------------------|------------------------------------------------------------------------------|
| No image version                | Uses `python:3.13`                                                       |
| Secret hardcoded in Dockerfile | Removed; now passed via runtime env var `SECRET`                             |
| Unnecessary layers              | Combines `apt-get update && install` into one layer                          |
| Shell access possible          | Removes `/bin/bash` to block `docker exec -it container bash`               |
| Unclean APT cache              | Removes `/var/lib/apt/lists/*` to reduce image size and remove cache        |



### 🛠️ Hardened Dockerfile
```Dockerfile
FROM python:3.13

# Remove bash to prevent interactive execs
RUN apt-get update && apt-get install -y --no-install-recommends curl && \
    rm /bin/bash && \
    rm -rf /var/lib/apt/lists/*

# Copy app code
COPY main.py /app/main.py
WORKDIR /app

# Do NOT hardcode the secret here
CMD ["python", "main.py"]
```

### 📄 main.py (unchanged)
```python
import os

secret = os.environ.get("SECRET")
if secret:
    print(f"\ud83d\udd10 The secret is: {secret}")
else:
    print("\u274c No secret provided.")
```

---

---

### 🧪 Test Commands

Build the image:

```bash
docker build -t secure-app .
```
Run with a secret:

```bash
$ docker run -e SECRET=12345 secure-app
🔐 The secret is: 12345
🕒 Sleeping for 3600 seconds to keep the container alive...
```

Try to exec into it with bash:
```
$ docker container ls
CONTAINER ID   IMAGE     COMMAND               CREATED          STATUS          PORTS     NAMES
498accd6b40c   app:v4    "python -u main.py"   10 seconds ago   Up 10 seconds             festive_sutherland

$ docker exec -it festive_sutherland bash
OCI runtime exec failed: exec failed: unable to start container process: exec: "bash": executable file not found in $PATH: unknown
```

---

### 📚 References
- Dockerfile Best Practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
