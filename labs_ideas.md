1. Create a Pod with a mounted Secret and exfiltrate it via log output using a restricted user — difficulty: intermediate, domain: Cluster Hardening
2. Use a misconfigured ServiceAccount token inside a Pod to access the Kubernetes API and retrieve a secret — difficulty: difficult, domain: Cluster Hardening
3. Inject environment variables from a Secret into a Pod and extract them through the env command — difficulty: intermediate, domain: Cluster Hardening
4. Configure a PodSecurity Standard policy to restrict privileged containers and attempt a deployment that violates it — difficulty: easy, domain: Cluster Hardening
5. Apply seccomp and AppArmor profiles to a Pod and verify its runtime behavior with them enabled — difficulty: intermediate, domain: System Hardening
6. Deploy OPA Gatekeeper and enforce required labels on Pods in a namespace using a custom ConstraintTemplate — difficulty: intermediate, domain: Cluster Hardening
7. Write a Rego policy in Gatekeeper to deny Pods with hostPath volumes and test it — difficulty: difficult, domain: Cluster Hardening
8. Set up audit logging on the API server and identify actions taken by a specific user — difficulty: intermediate, domain: Monitoring, Logging & Runtime Security
9. Install and configure Falco to detect a container running netcat and alert on suspicious network activity — difficulty: intermediate, domain: Monitoring, Logging & Runtime Security
10. Create a Pod with a writable hostPath mount and exploit it to modify the host system — difficulty: difficult, domain: System Hardening
11. Enable PodSecurity Admission with enforce mode and try deploying Pods that violate baseline and restricted profiles — difficulty: intermediate, domain: Cluster Hardening
12. Use network policies to isolate a frontend service and test egress/ingress restrictions — difficulty: intermediate, domain: Cluster Hardening
13. Deploy Trivy Operator and scan existing workloads for vulnerabilities and misconfigurations — difficulty: intermediate, domain: Minimize Microservice Vulnerabilities
14. Create a Kubernetes Job that writes a secret to a world-readable ConfigMap and detect the issue — difficulty: difficult, domain: Supply Chain Security
15. Set resource requests and limits and enforce them via OPA Gatekeeper mutation — difficulty: intermediate, domain: Cluster Hardening
16. Deploy a container image from an unknown registry and scan it with Trivy CLI before allowing its use — difficulty: intermediate, domain: Supply Chain Security
17. Enforce use of specific trusted registries using OPA policies — difficulty: difficult, domain: Supply Chain Security
18. Setup gVisor with containerd and enforce its use via runtimeClass for high-security Pods — difficulty: difficult, domain: System Hardening
19. Detect use of curl or wget inside containers using Falco — difficulty: intermediate, domain: Monitoring, Logging & Runtime Security
20. Implement secrets encryption at rest with a custom encryption provider — difficulty: difficult, domain: Cluster Hardening
21. Write a validating admission webhook that rejects Pods without a seccompProfile set — difficulty: difficult, domain: System Hardening
22. Deploy a sidecar container that exposes credentials and use another container to capture them — difficulty: difficult, domain: Supply Chain Security
23. Force read-only root filesystem via PodSecurityPolicy or PSA and attempt writes — difficulty: intermediate, domain: Cluster Hardening
24. Create a namespace where automountServiceAccountToken is disabled and test access from inside pods — difficulty: intermediate, domain: Cluster Hardening
25. Block imagePullPolicy: Always using Gatekeeper and allow only IfNotPresent — difficulty: intermediate, domain: Supply Chain Security
26. Create a deployment using image digest pinning instead of tags and validate with a policy — difficulty: intermediate, domain: Supply Chain Security
27. Setup Kubernetes Dashboard and restrict access using RBAC and TLS — difficulty: intermediate, domain: Cluster Hardening
28. Use `kubectl auth can-i` to test user permissions across various resources — difficulty: easy, domain: Cluster Hardening
29. Explore escalation via misconfigured RoleBindings that bind ClusterRoles in a namespace — difficulty: difficult, domain: Cluster Hardening
30. Capture outbound connections from Pods using tcpdump or a Falco rule — difficulty: difficult, domain: Monitoring, Logging & Runtime Security
31. Restrict container capabilities using drop: ALL and test the effect on container operations — difficulty: intermediate, domain: System Hardening
32. Deploy a mutating webhook that injects runtimeClassName=gvisor to Pods with label security=high — difficulty: difficult, domain: System Hardening
33. Create a Rego constraint to block the use of imagePullSecrets unless from an allowed list — difficulty: difficult, domain: Supply Chain Security
34. Use Trivy to scan a Helm chart directory before deployment — difficulty: intermediate, domain: Supply Chain Security
35. Create a Helm chart with a secret rendered in a template and detect it using Trivy — difficulty: difficult, domain: Supply Chain Security
36. Simulate a crypto miner container and detect its behavior with Falco — difficulty: difficult, domain: Monitoring, Logging & Runtime Security
37. Monitor for shell binaries executed inside running containers — difficulty: intermediate, domain: Monitoring, Logging & Runtime Security
38. Use PSP or PSA to block use of hostNetwork and verify enforcement — difficulty: intermediate, domain: Cluster Hardening
39. Run a Pod with hostPID and use ps to inspect host processes — difficulty: difficult, domain: System Hardening
40. Enforce SELinux context via Pod annotations and observe denied access in logs — difficulty: difficult, domain: System Hardening
41. Implement CIS benchmark scans using kube-bench and interpret results — difficulty: intermediate, domain: Cluster Hardening
42. Setup auditd on a node and correlate system-level activity with Kubernetes API events — difficulty: difficult, domain: Monitoring, Logging & Runtime Security
43. Rotate a Kubernetes Secret and ensure zero downtime update in a Deployment — difficulty: intermediate, domain: Minimize Microservice Vulnerabilities
44. Enforce image signature verification using cosign and Gatekeeper — difficulty: difficult, domain: Supply Chain Security
45. Create an etcd backup and restore scenario for disaster recovery — difficulty: intermediate, domain: Cluster Hardening
46. Simulate a supply chain attack via base image compromise and detect it with image scanning — difficulty: difficult, domain: Supply Chain Security
47. Monitor service account token usage frequency to detect anomalies — difficulty: difficult, domain: Monitoring, Logging & Runtime Security
48. Write a PodSecurityPolicy that allows only specific user/group IDs and test enforcement — difficulty: intermediate, domain: System Hardening
49. Use `kubectl diff` to observe unapproved changes between declared and live resources — difficulty: intermediate, domain: Cluster Hardening
50. Build a CI pipeline that signs images and prevents unsigned images from being deployed — difficulty: difficult, domain: Supply Chain Security
51. Exploit secret leakage via container logs and detect it using centralized logging — difficulty: difficult, domain: Monitoring, Logging & Runtime Security
52. Create a read-only ConfigMap volume and verify that modification fails — difficulty: easy, domain: System Hardening
53. Inject a fake root certificate into a container and use it to MITM outgoing TLS traffic — difficulty: difficult, domain: System Hardening
54. Block image tags like latest using Gatekeeper and enforce image digest pinning — difficulty: intermediate, domain: Supply Chain Security
55. Detect base64-encoded secrets embedded in Pod spec using Trivy custom policies — difficulty: intermediate, domain: Supply Chain Security
56. Use network policy to block access to internal services and validate isolation — difficulty: intermediate, domain: Cluster Hardening
57. Set up centralized audit log forwarding using FluentBit and correlate events — difficulty: difficult, domain: Monitoring, Logging & Runtime Security
58. Limit Pod egress using egress NetworkPolicies and confirm DNS and HTTP access — difficulty: intermediate, domain: Cluster Hardening
59. Enforce seccomp profile default for all workloads and detect violations — difficulty: intermediate, domain: System Hardening
60. Create a policy to reject workloads running as root — difficulty: intermediate, domain: System Hardening
61. Detect changes in ConfigMaps used by critical workloads and raise alerts — difficulty: intermediate, domain: Monitoring, Logging & Runtime Security
62. Create a malicious Job that accesses host volume and detect it with Falco — difficulty: difficult, domain: Monitoring, Logging & Runtime Security
63. Implement AppArmor policy and test its enforcement using a restricted syscall — difficulty: difficult, domain: System Hardening
64. Block creation of containers with NET_ADMIN capability — difficulty: intermediate, domain: System Hardening
65. Deny usage of hostPorts in Pod definitions using OPA policies — difficulty: intermediate, domain: System Hardening
66. Run vulnerability scans on Kubernetes manifests before deployment — difficulty: intermediate, domain: Supply Chain Security
67. Simulate a secret exposure via environment variables and detect with Falco — difficulty: difficult, domain: Monitoring, Logging & Runtime Security
68. Use pod topology spread constraints to avoid single node workload concentration — difficulty: intermediate, domain: Cluster Hardening
69. Validate PodDisruptionBudgets are defined for high availability — difficulty: intermediate, domain: Cluster Hardening
70. Monitor and alert on containers with long uptimes — difficulty: intermediate, domain: Monitoring, Logging & Runtime Security
71. Rotate kubelet server certificate and observe changes — difficulty: difficult, domain: Cluster Hardening
72. Prevent deletion of critical namespaces via RBAC and test bypasses — difficulty: difficult, domain: Cluster Hardening
73. Deploy an image that pulls a malicious payload and detect it using runtime analysis — difficulty: difficult, domain: Supply Chain Security
74. Use imagePolicyWebhook to block unsigned or non-compliant images — difficulty: difficult, domain: Supply Chain Security
75. Create a policy that ensures all deployments have replicas >= 2 — difficulty: easy, domain: Cluster Hardening
76. Test the effect of removing CAP_SYS_ADMIN in container securityContext — difficulty: intermediate, domain: System Hardening
77. Detect excessive container restarts and correlate with liveness probe failures — difficulty: intermediate, domain: Monitoring, Logging & Runtime Security
78. Block access to cloud metadata endpoints from within containers — difficulty: intermediate, domain: Cluster Hardening
79. Use runtimeClass to isolate sensitive Pods using gVisor — difficulty: difficult, domain: System Hardening
80. Write an OPA policy to block specific node selectors in deployments — difficulty: intermediate, domain: Cluster Hardening
81. Limit node affinity to production nodes and test RBAC for anti-affinity — difficulty: intermediate, domain: Cluster Hardening
82. Test access to mounted secrets from sidecar containers — difficulty: intermediate, domain: Cluster Hardening
83. Use tools like kyverno to auto-label sensitive resources — difficulty: intermediate, domain: Cluster Hardening
84. Enforce Registry scanning on container push events via admission webhook — difficulty: difficult, domain: Supply Chain Security
85. Simulate CVE exposure through vulnerable container images — difficulty: difficult, domain: Supply Chain Security
86. Create policy that mandates liveness and readiness probes — difficulty: intermediate, domain: Cluster Hardening
87. Use pod anti-affinity to enforce physical workload separation — difficulty: intermediate, domain: Cluster Hardening
88. Prevent escalation by disallowing use of serviceAccountName in Pod specs — difficulty: intermediate, domain: Cluster Hardening
89. Test certificate expiration detection in kubelet TLS bootstrap — difficulty: difficult, domain: Cluster Hardening
90. Use admission controllers to inject security context in all Pods — difficulty: difficult, domain: System Hardening
91. Audit service accounts with access to sensitive verbs — difficulty: intermediate, domain: Cluster Hardening
92. Simulate attack with container escape using a vulnerable binary — difficulty: difficult, domain: System Hardening
93. Monitor kube-proxy logs for iptables rule injection — difficulty: difficult, domain: Monitoring, Logging & Runtime Security
94. Alert on changes to RBAC roles via Kubernetes audit logs — difficulty: difficult, domain: Monitoring, Logging & Runtime Security
95. Backup and verify etcd secrets on a scheduled basis — difficulty: intermediate, domain: Cluster Hardening
96. Detect unbound PVCs and alert on data availability risks — difficulty: intermediate, domain: Cluster Hardening
97. Force annotation presence for audit traceability — difficulty: intermediate, domain: Cluster Hardening
98. Detect potential lateral movement using service account enumeration — difficulty: difficult, domain: Monitoring, Logging & Runtime Security
99. Audit unauthorized kubectl exec usage across namespaces — difficulty: difficult, domain: Monitoring, Logging & Runtime Security
100. Simulate a compromised image registry and validate alerting and RBAC protections — difficulty: difficult, domain: Supply Chain Security


# 💥 Liste complète de labs intermédiaires et avancés pour le CKS (par domaine)

Chaque domaine contient **15 labs**, orientés vers la **pratique du CKS**, du niveau **intermédiaire à difficile**, en excluant les exercices trop basiques.

---
# 💥 Liste complète de labs intermédiaires et avancés pour le CKS (par domaine)

Chaque domaine contient **20 labs**, orientés vers la **pratique du CKS**, du niveau **intermédiaire à difficile**, en excluant les exercices trop basiques.

---

## 🏗️ Cluster Setup 

1. Installer un cluster Kubernetes avec containerd et Cilium (WireGuard activé)
2. Configurer OPA Gatekeeper dès le bootstrap avec contraintes de base
3. Activer les audit logs Kubernetes avec règles personnalisées
4. Configurer le runtime gVisor via RuntimeClass et l'appliquer à des workloads
5. Isoler le plan de contrôle avec des taints et des labels
6. Séparer les workloads dans des namespaces avec quotas et politiques réseau
7. Configurer les logs de containerd et rotation des journaux
8. Configurer etcd en HTTPS avec authentification mTLS
9. Activer le chiffrement des secrets au repos via une clé AES personnalisée
10. Automatiser la configuration sécurisée via kubeadm + patch YAML + script de post-install
11. Forcer la version de TLS sur les composants kube-apiserver/kubelet/kube-proxy
12. Installer un cluster avec des nœuds hétérogènes (taints, rôles, labels) et policies associées
13. Vérifier les permissions des sockets (docker.sock, containerd.sock) en post-install
14. Script d’installation durci avec journalisation et rollback automatique
15. Intégrer Kyverno dès l’installation avec règles de conformité dès le 1er pod
16. Démarrer un cluster avec un user non-root + RBAC + accès audit log
17. Provisionner un cluster HA avec control-plane répartis et secrets chiffrés
18. Mettre en place une infra temporaire (cluster ephemeral) pour tests de sécurité
19. Vérifier la sécurité des images d’installation (binaire kubeadm, cri-tools)
20. Préparer un cluster CKS simulé avec vulnérabilités intégrées pour formation
21. Appliquer un profil BOM (Benchmark Of Mitigation) dès l'installation avec kube-bench + playbook d'application correctives
---

## 🔐 Cluster Hardening 

1. Détecter et bloquer un pod malveillant avec Falco + NetworkPolicy
2. Interdire les pods privilégiés avec OPA Gatekeeper et Rego
3. Restreindre les permissions via RBAC avec accès granulaire
4. Créer une politique PodSecurityAdmission `restricted` multi-namespaces
5. Auditer la configuration Kubelet avec kube-bench et corriger les alertes
6. Mettre en place une règle Gatekeeper pour forcer les probes (liveness/readiness)
7. Empêcher l’utilisation de volumes hostPath sauf whitelist
8. Configurer Seccomp audit + enforcement sur pods sensibles
9. Empêcher la montée de privilèges via `allowPrivilegeEscalation: false` + audit Falco
10. Restreindre les nœuds via taints + nodeAffinity + NetworkPolicy
11. Restreindre l’utilisation de ports hostPort et hostNetwork via Gatekeeper
12. Implémenter l’audit des ConfigMap sensibles (ex : .kube/config exposé)
13. Supprimer les tokens montés par défaut dans certains pods (automountServiceAccountToken)
14. Forcer des UID spécifiques à certains workloads via mutation policy
15. Protéger les secrets montés avec des règles d’accès spécifiques (volumes + RBAC)
16. Appliquer une règle pour interdire les annotations `kubectl.kubernetes.io/last-applied-configuration`
17. Utiliser une admission policy pour refuser les labels non standards sur pods
18. Évaluer le risque d’un cluster exposé sur Internet (simulateur + fix)
19. Configurer la rotation automatique des secrets service account
20. Forcer les limites mémoire/CPU sur toutes les ressources par namespace via Gatekeeper
21. Appliquer les correctifs CIS pour les permissions /etc/kubernetes/manifests/*.yaml (1.1.x kube-bench)
22. Durcir les arguments du kube-apiserver (--audit-log-path, --profiling=false) via BOM CIS
23. Corriger les erreurs kube-bench sur le --authorization-mode=Node,RBAC dans le manifeste apiserver
---

## 🛡️ System Hardening

1. Créer un profil AppArmor et l’appliquer via annotations Kubernetes
2. Auditer le système avec kube-bench (profil node)
3. Activer et tester un profil seccomp sur différents workloads
4. Configurer auditd pour capturer les accès au binaire `docker` ou `crictl`
5. Bloquer l’accès au socket Docker via permissions et AppArmor
6. Forcer les permissions des sockets containerd avec `systemd`
7. Durcir le fichier `/etc/hosts` et `/etc/passwd` via readonly root filesystem
8. Empêcher l’accès aux outils réseau (`ping`, `curl`, etc.) via AppArmor
9. Détecter les modifications système via un Falco rule custom (fichier sensible)
10. Bloquer les syscalls liés à mount ou ptrace avec un profil seccomp custom
11. Activer SELinux avec une politique custom sur un cluster test (CentOS/RHEL)
12. Scanner le nœud avec Lynis ou OpenSCAP pour évaluer la base OS
13. Restreindre les accès SSH sur les nœuds workers et auditer les connexions
14. Sécuriser les partitions système en lecture seule (fstab, tmpfs, /var/lib/kubelet)
15. Activer l’audit du trafic sortant des nœuds via iptables/ebpf
16. Surveiller la liste des binaires suid et leur modification dans `/usr/bin`
17. Implémenter une règle de sécurité empêchant la suppression de logs `/var/log`
18. Protéger les processus système via une règle de détection d’élévation UID
19. Empêcher le mount de FS externes (NFS, CIFS) via Policy ou AppArmor
20. Script d’audit complet automatisé d’un nœud CKS (résultat + mitigation)
21. Scanner un nœud avec kube-bench (profil node) et appliquer les correctifs BOM en script
22. Écrire un TP avec les règles kube-bench prioritaires : auditd actif, journalctl protégé, fichiers /etc/kubernetes/ sécurisés
---

## 🐳 Minimize Microservice Vulnerabilities 

1. Utiliser Trivy CLI pour scanner une image + refuser son déploiement via webhook
2. Limiter les capabilities (`drop: ["ALL"]`) via Gatekeeper ou PodSpec
3. Forcer `readOnlyRootFilesystem: true` + `runAsNonRoot` avec mutation
4. Configurer des probes correctes pour tous les services critiques
5. Isoler les services par namespace avec NetworkPolicy stricte
6. Détecter un comportement anormal avec Tracee (ex : shell ouvert)
7. Forcer l’usage d’un UID/GID non root dans tous les conteneurs
8. Créer une alerte Falco sur exécution de commandes systèmes interdites
9. Limiter les accès `/proc` et `/sys` via AppArmor et seccomp
10. Mettre à jour dynamiquement les règles Gatekeeper à chaud sans downtime
11. Appliquer une configuration read-only sur les volumes montés (subPath + accessMode)
12. Éviter l'exposition d'admin panels internes via une politique d'ingress + regex
13. Analyser une image compromise avec dive et Trivy (layers suspects)
14. Mettre en place un process SRE pour roll-back immédiat d’image vulnérable
15. Activer la vérification automatique de dépendances vulnérables dans un pod NodeJS
16. Limiter la taille mémoire d'un pod + OOM kill + alerte Falco
17. Empêcher l’exécution de fichiers temporaires dans `/tmp` via AppArmor
18. Forcer l’utilisation d’une image spécifique avec digest (immutable tags)
19. Implémenter une règle Kyverno pour interdire les containers multiples dans un pod
20. Scanner à chaud une image déjà en exécution (Trivy + container ID)

---

## 🔗 Supply Chain Security 

1. Signer une image avec Cosign, vérifier la signature via Kyverno
2. Mettre en place un ImagePolicyWebhook pour refuser les images non scannées
3. Scénario GitOps avec FluxCD et enforcement des manifest signés
4. Scanner une image dans le pipeline CI avec Trivy + déploiement bloqué si vulnérabilité
5. Bloquer le pull d’images publiques (docker.io) sauf whitelist
6. Vérifier les dépendances (Node.js ou Python) avec Trivy + refuser si vulnérabilités
7. Appliquer des règles Kyverno pour exiger `imagePullPolicy: Always`
8. Restreindre les registres autorisés via AdmissionPolicy
9. Activer et tester le cache local Trivy pour CI/CD sécurisé
10. Simuler une compromission d’image et observer la détection via Falco + admission
11. Forcer la vérification de provenance dans le pipeline (provenance attestations)
12. Mettre en place une registry privée durcie avec authentification mTLS
13. Utiliser Kyverno + Cosign pour valider les champs `issuer`, `subject` dans la signature
14. Bloquer l’usage de Dockerfile contenant `ADD`, `apt install`, ou `curl` sans checksum
15. Détecter l’usage de secrets codés en dur dans le Git via TruffleHog
16. Vérifier la provenance des charts Helm avec provenance.yaml et cosign
17. Ajouter une étape de signature dans le CI GitHub Actions via `cosign sign`
18. Empêcher les images "latest" dans un cluster via Gatekeeper ou Kyverno
19. Forcer un hash digest (`sha256:`) dans tous les manifests de déploiement
20. Scanner automatiquement les PRs avec un GitHub bot (Trivy + Action)
21. TP complet : installer Trivy Operator, scanner les workloads, exporter les résultats dans Prometheus, afficher dans Grafana
---

## 📊 Monitoring, Logging & Runtime Security 

1. Déployer Falco et déclencher une alerte sur `apt install` dans un pod
2. Exporter les alertes Falco dans Prometheus et visualiser via Grafana
3. Configurer audit logs Kubernetes et écrire une règle personnalisée
4. Utiliser Trivy Operator pour scanner les workloads et exposer les métriques
5. Créer un dashboard Grafana filtrant les pods avec vulnérabilités critiques
6. Simuler une compromission et déclencher une action automatique (scale 0)
7. Configurer Tracee pour journaliser tous les appels `execve` suspects
8. Monitorer les namespaces sensibles avec une politique runtime dédiée
9. Intégrer Promtail + Loki pour audit centralisé des pods et nœuds
10. Créer une alerte Prometheus sur activité anormale (spike de syscalls, fail login)
11. Mettre en place des `recording rules` dans Prometheus pour visualiser les tendances d’attaque
12. Configurer alertmanager pour envoyer des alertes sur Telegram/Slack lors de violation
13. Déployer kube-audit-log-bridge pour rediriger les audit logs vers Loki
14. Identifier les pods actifs sans probe ni logging via un script de conformité
15. Simuler un reverse shell dans un pod et observer les détections en cascade (Falco, Tracee, Alertmanager)
16. Visualiser l’évolution des niveaux de vulnérabilités sur 7 jours (time series)
17. Ajouter un pipeline Loki → OpenSearch pour forensic post-compromission
18. Forcer la journalisation des appels `kubectl exec` avec webhook et audit log
19. Observer les pics d’utilisation réseau par pod (NetFlow/KubeNet observability)
20. Automatiser le déclenchement d’un snapshot node (fs, RAM) après événement critique

