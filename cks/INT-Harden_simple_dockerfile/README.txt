🔐 Lab: Harden a Python-based Docker Container

🧠 Difficulty: Intermediate  
⏱️ Estimated Time: 15 minutes

🎯 Goal:  
- You are given an insecure Dockerfile using Python in `~/docker`. 
- Your task is to apply container hardening best practices to make it production-ready and secure.

📌 Your tasks:

1. Use a specific version of the base image (e.g., python:3.13)
2. Remove the hardcoded secret from the Dockerfile
3. Make the secret injectable via an environment variable at runtime
4. Prevent interactive access to the container using `/bin/bash`
5. Optimize layers and security
6. DO NOT ADD/CHANGE THE USER

🧪 Test:
Build the container:
  $ sudo docker build -t secure-app .

Run the container with a secret:
  $ sudo docker run -e SECRET=your-secret-value secure-app

Expected Output:
  🔐 The secret is: your-secret-value

📛 Tests :
  $ sudo docker run -d -e SECRET=your-secret-value secure-app
  $ sudo docker ps
  $ sudo docker exec -it <container_id> bash    # should fail
  $ sudo docker exec -it <container_id> sh      # might still work

🧹 A reset.sh script is available to clean local images and containers.
