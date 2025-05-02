## ✅ Solution: Harden an Insecure Dockerfile

This solution demonstrates how to improve a poorly written and insecure Dockerfile for a NodeJS application.

---

### 🔍 Original Insecure Dockerfile


```Dockerfile
FROM node:latest

WORKDIR /app

COPY package*.json ./
RUN apt-get update
RUN apt-get install -y curl
RUN npm install
RUN apt-get clean

COPY . .

EXPOSE 3000
CMD ["npm", "start"]
```

We can build the image :

```
$ docker build -t node-app:v1 .
...
$ docker image ls 
REPOSITORY   TAG       IMAGE ID       CREATED         SIZE
node-app     v1        1a40ae87cd42   4 minutes ago    1.15GB
```

```
$ docker run --rm -it node-app:v1 id
uid=0(root) gid=0(root) groups=0(root)

$ docker run --rm -it node-app:v1

> testapp@1.0.0 start
> node index.js

🚀 NodeJS app started !
^C
```


### ❌ Issues in the Original Dockerfile
1. **Unpinned base image**: `node:latest` can change over time, leading to non-reproducible builds.
2. **Multiple `RUN` layers**: creates a larger image and makes it harder to maintain.
3. **No cleanup**: `apt-get clean` only removes downloaded `.deb` files. To fully clean up, you must also run `rm -rf /var/lib/apt/lists/*` to remove cached package lists.
4. **No non-root user**: running as root is a security risk.
5. **COPY . .**: copies everything, including potentially sensitive or unnecessary files.
6. *(Optional)* **Missing `.dockerignore`**: can cause large/unnecessary context.

---

### ✅ Improved Dockerfile

And the new `Dockerfile` :

```Dockerfile
FROM node:23.11-slim

# Create and use a non-root user
RUN useradd -m appuser

WORKDIR /app

# Install only needed tools and cleanup immediately
RUN apt-get update \
  && apt-get install -y --no-install-recommends curl \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Copy only what's needed first to leverage Docker cache
COPY package*.json ./
RUN npm install

# Copy the only application code 
COPY index.js .

# Drop privileges
USER appuser

EXPOSE 3000
CMD ["npm", "start"]
```

We build image and we test it :

```
$ docker build -t node-app:v2 .
...
$ docker image ls
REPOSITORY   TAG       IMAGE ID       CREATED          SIZE
node-app     v2        dd3046f8523d   17 seconds ago   241MB
node-app     v1        1a40ae87cd42   4 minutes ago    1.15GB


$ docker run --rm -it node-app:v2 id
uid=1001(appuser) gid=1001(appuser) groups=1001(appuser)

$ docker run --rm -it node-app:v2

> testapp@1.0.0 start
> node index.js

🚀 NodeJS app started !
^C
```

We can notice the difference in image sizes and the user is no longer `root` !

### 📦 Optional Improvement: Avoid COPY . .

While `COPY . .` is simple, it can copy unnecessary files (e.g. .git, README, local configs). A minimal improvement would be:

```
COPY index.js .
```

Or using a `.dockerignore` file to exclude unwanted content. This helps reduce image size and avoid leaking sensitive files.

### 🛠 Additional Best Practices

We can add :

- **Use `.dockerignore`** to exclude files like `.git`, `node_modules`, `README.md`, etc.
- **Consider multistage builds** for even smaller final images.
  **RUN npm install --omit=dev** excludes development dependencies (lighter production image).
- **but better, we can use `npm ci`** installs exact versions from `package-lock.json` and is faster/more reproducible. Use it in CI/CD pipelines when package-lock.json is present. Not required in this CKS lab.
- **Avoid unnecessary tools** like `git` unless needed during build.

---

### ❓ Why `RUN` steps are often not merged
While merging multiple commands into a single `RUN` instruction reduces the number of image layers and can slightly optimize image size, it's not always the best approach. In this case, we do not merge in one RUN stage the apt-get commands and npm install. That way, if there is a change in the app (here index.js), no need to run the entire layer with `apt-get` commands.

Separating `RUN` instructions, especially for distinct concerns like package installation vs. application dependency installation, brings benefits:

- ✅ **Better caching**: Docker will cache each step independently. If you update your system packages but not your NodeJS dependencies, only the relevant layer is rebuilt.
- 🐛 **Easier debugging**: If something goes wrong, it's easier to trace the failure to a specific step.
- 👥 **Team clarity**: Different devs can modify and test parts independently.
- 🔄 **Faster CI builds**: Separation reduces rebuild time when only part of the image changes.

That said, for simple Dockerfiles or when image size is a top priority, merging is perfectly valid and can be encouraged.

### ✅ Expected Outcome
- Smaller image size
- More secure (non-root user, fixed versions, cleanup)
- Fewer attack surfaces
- Maintains same application behavior (still runs `npm start` on port 3000`)

## 📚 References
- [Best practices for writing Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
