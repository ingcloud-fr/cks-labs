🛡️ Lab: Harden an Insecure Dockerfile

🧠 Difficulty: Intermediate  
⏱️ Estimated Time: 10–15 minutes

🎯 Goal:  
You are given a Dockerfile that builds and runs a NodeJS application.  
Your task is to identify and fix security issues and bad practices in it.

📌 Your mission:

1. The provided `Dockerfile` is located in `/home/vagrant/docker` with a (very) simple js app in a single file `index.js`
2. Improve the Dockerfile based on best practices:
   - Use a minimal base image with a fixed tag (search for `slim` in node images on Docker Hub)
   - Combine `apt-get` commands and clean up properly
   - Avoid running as root
   - Use a dedicated non-root user
   - Minimize layers when possible
   - Reduce image size and attack surface

NOTE: You can build the image to compare sizes.

✅ Expected:
- The final image should build successfully
- The application should run with `docker run` using `npm start`
- The container must run as non-root

🧹 A `reset.sh` script is available to restore the original Dockerfile if needed.
