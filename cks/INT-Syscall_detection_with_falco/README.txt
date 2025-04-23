🛡️ Lab: Detecting Unauthorized System Behavior with Falco

🧠 Difficulty: Intermediate  
⏱️ Estimated Time: 15-20 minutes

🎯 Goal:  
One of the deployed pods is trying to alter critical system files. Another is installing new software — both are suspicious behaviors.

📌 Your mission:
1. Use Falco (already installed) to identify which pods are exhibiting unusual behavior.
2. Investigate their logs and detect:
   - One pod writing to /etc/shadow
   - One pod running a package manager
3. Modify logging rule in Falco (see Expected result)
4. Scale the corresponding deployments to 0 to neutralize the threats.

🧰 Context:
- Three namespaces are created: `team-green`, `team-blue`, `team-red`.
- Three applications are deployed. Two are misbehaving.
- Falco is installed but **not running as a service**. You must launch it manually.

✅ Expected result:

- The suspicious deployment which tries to write in /etc/shadow is scaled down to 0.
- Modify the Falco Rule `Package manager execution detected` to extend log with 
   - the time (without nanoseconds)
   - user_name
   - the command 
   - the container id (already existing)
   - the container name 
   - the image_repo
   - AND change the priority to `Alert`
- The both nodes must have the same Falco rules
- Once you checked that the new log is ok, you can scale down to 0 the deployment.

⚠️  You may use sudo on nodes

📚 You can use Falco documentation at https://falco.org/

