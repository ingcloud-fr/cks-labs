# olution: BOM, CVE and Library Analysis using Trivy CLI

## 🔍 Objective Recap

Select the safest image among the following:

- `nginx:1.22-alpine`
- `nginx:1.19.10-alpine-perl`
- `cgr.dev/chainguard/nginx:latest`

Based on the following criteria:

- No **HIGH** or **CRITICAL** vulnerabilities in the `libexpat` package
- No presence of **CVE-2018-25032**

---

## ✅ Step 1: Generate SBOMs with cyclonedx format



```bash
$ trivy image --format cyclonedx -o nginx-1.22-alpine.sbom.json nginx:1.22-alpine
$ trivy image --format cyclonedx -o nginx-1.19.10-alpine-perl.sbom.json nginx:1.19.10-alpine-perl
$ trivy image --format cyclonedx -o nginx-chainguard.sbom.json cgr.dev/chainguard/nginx:latest
```

---

## ✅ Step 2: Generate Trivy report from SBOM

Run a scan **from the SBOM** to target only high/critical CVEs:

```bash
$ trivy sbom nginx-1.22-alpine.sbom.json --severity HIGH,CRITICAL > result-1.22.txt
$ trivy sbom nginx-1.19.10-alpine-perl.sbom.json --severity HIGH,CRITICAL > result-1.19.txt
$ trivy sbom nginx-chainguard.sbom.json --severity HIGH,CRITICAL > result-chainguard.txt
```

You can search directly:

```
$ grep -E "libexpat|CVE-2018-25032" result-1.19.txt 
│                       │ CVE-2018-25032 │ HIGH     │        │                   │ 1.2.12-r0        │ zlib: A flaw found in zlib when compressing (not             │
```

```
$ grep -E "libexpat|CVE-2018-25032" result-1.22.txt 
│ libexpat              │ CVE-2024-45491 │ CRITICAL │        │ 2.5.0-r0          │ 2.6.3-r0         │ libexpat: Integer Overflow or Wraparound                     │
│                       │ CVE-2024-45492 │          │        │                   │                  │ libexpat: integer overflow                                   │
│                       │ CVE-2024-45490 │          │        │                   │ 2.6.3-r0         │ libexpat: Negative Length Parsing Vulnerability in libexpat  │
```

```
$ grep -E "libexpat|CVE-2018-25032" result-chainguard.txt 
$ <empty>
```

Or :

```bash
grep -i libexpat result-*.txt
grep -i CVE-2018-25032 result-*.txt
```

---

## 🔫 Step 4: Vulnerability Findings

### ❌ nginx:1.22-alpine
- Contains `libexpat` with **HIGH**/CRITICAL vulnerabilities.
- Does **not** contain CVE-2018-25032.

### ❌ nginx:1.19.10-alpine-perl
- `libexpat` has **no high/critical** vulnerabilities
- But image contains **CVE-2018-25032**

### ✅ cgr.dev/chainguard/nginx:latest
- `libexpat` is present but has **no high/critical CVEs**
- **CVE-2018-25032** is **not present**

## 🔍 Bonus: Use jq to Query SBOM & CVEs

You can automate analysis with `jq`.

For instance, to find `libexpat` in the SBOM :

```json
$ jq '.components[] | select(.name | test("libexpat")) | {name, version}' nginx-1.22-alpine.sbom.json 
{
  "name": "libexpat",
  "version": "2.5.0-r0"
}
```


Or to check for CVE-2018-25032 in scanned SBOM :


```
$ sudo trivy sbom --format json -o result.json nginx-1.19.10-alpine-perl.sbom.json 
```
And :

```json
$ jq '.Results[].Vulnerabilities[]? | select(.VulnerabilityID=="CVE-2018-25032")' result.json
{
  "VulnerabilityID": "CVE-2018-25032",
  "PkgID": "zlib@1.2.11-r3",
  "PkgName": "zlib",
  "PkgIdentifier": {
    "PURL": "pkg:apk/alpine/zlib@1.2.11-r3?arch=x86_64&distro=3.13.5",
    "UID": "e46b8ae1c3ed1b3b",
    "BOMRef": "pkg:apk/alpine/zlib@1.2.11-r3?arch=x86_64&distro=3.13.5"
  },
  "InstalledVersion": "1.2.11-r3",
  "FixedVersion": "1.2.12-r0",
```

## 📚 Final Decision

**Selected Image:** `cgr.dev/chainguard/nginx:latest`

### 🌟 Why?
- No critical vulnerabilities on `libexpat`
- No presence of `CVE-2018-25032`
- Chainguard images follow security best practices and are minimal, signed, and updated frequently


## 🔗 References
- [Trivy Documentation](https://aquasecurity.github.io/trivy)
- [Chainguard Images](https://www.chainguard.dev/chainguard-images)


## 🔧 Good Practices
- Prefer distroless, Alpine, or Chainguard images
- Always scan with SBOM **and** image directly
- Focus on **critical components** (libssl, libc, libcurl, libexpat...)
- Document your decision and justification

