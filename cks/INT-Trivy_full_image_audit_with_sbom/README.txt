🔍 Lab: Secure Image Selection & SBOM Management with Trivy

🧠 Difficulty: Intermediate  
⏱️ Estimated Time: 20–30 minutes

🎯 Goal:  
Learn how to scan, analyze, and secure container images using Trivy CLI with Docker as the container engine.

📌 Your mission:

1. **Build an application image** using `Docker`:
   - Use the provided `Dockerfile` and demo Python app source code located in `demo-app/`.

2. **Scan your image** for vulnerabilities:
   - Use `trivy image` to detect CVEs in both OS packages and application dependencies.

3. **Analyze the scan results**:
   - Focus on high and critical vulnerabilities.
   - Identify and explain why certain base images may be unsafe.

4. **Improve image security**:
   - Choose a safer base image among the options below:
     - `python:3.9-alpine`: Lightweight, good for small attack surface.
     - `gcr.io/distroless/python3`: No package manager, secure-by-default.
     - `cgr.dev/chainguard/python:latest`: Hardened image using Wolfi, updated frequently.
   - Rebuild your image using Docker with the new base.

5. **Generate a Software Bill of Materials (SBOM)**:
   - Use Trivy to output a CycloneDX or SPDX formatted SBOM:  
     `trivy image --format cyclonedx --output sbom.json <your-image>`

6. **Inspect and validate the SBOM**:
   - Explore dependencies listed in the SBOM.
   - Identify any known vulnerable or outdated components.

7. **Generate a security report from the SBOM**:
   - Use `trivy sbom --input sbom.json` to analyze it directly from the SBOM file.

8. **Save and scan your image as a tarball**:
   - Save your image:  
     `docker save -o image.tar <your-image>`  
   - Scan the tarball with Trivy:  
     `trivy image --input image.tar`

🧰 Tools pre-installed:
- ✅ Trivy CLI
- ✅ Docker Engine
- ✅ A demo app with `Dockerfile` in `demo-app/`

✅ Expected results:
- A secure and optimized container image
- A generated SBOM file (CycloneDX or SPDX)
- A vulnerability scan derived from the SBOM
- Familiarity with Trivy CLI’s full image audit workflow including offline scans

🧹 Use `reset.sh` to clean your workspace and reset the lab between attempts.
