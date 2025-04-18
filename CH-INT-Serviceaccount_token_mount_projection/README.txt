🛡️ Lab: Launch a Pod using Service Account Token Projection

🧠 Difficulty: Intermediate  
⏱️ Estimated Time: 10–15 minutes

🎯 Goal:  
A pod must use a projected service account token instead of the default one.

📌 Your mission:
1. Create a service account named `project-sa` in `team-blue` namespace that does not auto-mount its token.
2. Modify the existing nginx deployment (in ~/manifest/) in `team-blue` namespace to project a service account token manually using:
   - a custom audience named `my-secure-audience`
   - a short expiration (2 hours = 7200 seconds)
   - a custom mount path `/var/run/secrets/projected-sa`
3. Verify the content of the projected token inside the pod.

🧰 Context:
- A namespace `team-blue` is created.
- A deployment named `nginx` is deployed using the `project-sa` service account.
- The manifest of the deployment is in ~/manifest.

✅ Expected result:
- The service account should not auto-mount any token.
- A projected token must be visible under `/var/run/secrets/projected-sa/token` inside the pod.
- The audience and expiration fields must be correctly set in the token payload.

🧹 A `reset.sh` script is available to clean the cluster between attempts.
