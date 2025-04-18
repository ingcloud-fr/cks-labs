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

1. Pull the three container images:
   - `nginx:1.22-alpine`
   - `nginx:1.19.10-alpine-perl`
   - `cgr.dev/chainguard/nginx:latest`

2. Generate a Software Bill of Materials (SBOM) for each image 
   - Format: CycloneDX
   - Example command:  
     `trivy image --format cyclonedx -o <image>.sbom.json <image>`

3. Inspect each SBOM:
   - Locate the `libexpat` package and note its version.
   - Check whether `libexpat` has any HIGH or CRITICAL vulnerabilities.

4. Scan each SBOM with Trivy:
   - Use the command:  
     `trivy sbom --input <image>.sbom.json --severity HIGH,CRITICAL`
   - Look for any occurrence of `CVE-2018-25032`.

5. Analyze and compare:
   - Identify which image has the fewest or no serious issues with `libexpat`.
   - Ensure the image does not contain `CVE-2018-25032`.

6. Select the safest image:
   - Justify your decision based on actual findings from the SBOM and scan results.

✅ Expected result:
- You must reject any image that:
  - Contains HIGH or CRITICAL vulnerabilities in `libexpat`
  - OR includes `CVE-2018-25032`
- Only one image is compliant.

🧹 A `reset.sh` script is available to clean your workspace.
