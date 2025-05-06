🛡️ Lab: Choose a Production-Safe Image by Targeting libexpat Vulnerabilities

🧠 Difficulty: Intermediate  
⏱️ Estimated Time: 15–20 minutes

📖 Context:

An application needs to use a `nginx`-based container image.  
The security team has asked you to perform a targeted analysis on the `libexpat` library to choose the safest image among the following:

- nginx:1.22-alpine  
- nginx:1.19.10-alpine-perl  
- cgr.dev/chainguard/nginx:latest  

⚠️ Additionally, the image **must not include** the HIGH vulnerability `CVE-2018-25032`.

---

🎯 Goal:  
Identify the most secure image based on a vulnerability analysis of `libexpat` and ensure the absence of `CVE-2018-25032`.

📌 Your mission:

1. Use Trivy to generate a Software Bill of Materials (SBOM) for each image in CycloneDX format :
   - `nginx:1.22-alpine`
   - `nginx:1.19.10-alpine-perl`
   - `cgr.dev/chainguard/nginx:latest`

2. Scan each SBOM with Trivy image :
   - Look for any occurrence of `CVE-2018-25032`.
   - Check whether `libexpat` has any HIGH or CRITICAL vulnerabilities.

3. Analyze and compare:
   - Identify which image has the fewest or no serious issues (HIGH or CIRITCAL) with `libexpat`.
   - Ensure the image does not contain `CVE-2018-25032`.

4. Select the safest image:
   - Justify your decision based on actual findings from the SBOM and scan results.

✅ Expected result:
- You must reject any image that:
  - Contains HIGH or CRITICAL vulnerabilities in `libexpat`
  - OR includes `CVE-2018-25032`
- Only one image is compliant.

🧹 A `reset.sh` script is available to clean your workspace.
