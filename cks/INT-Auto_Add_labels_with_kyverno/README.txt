🛡️ Lab: Auto-Add Labels to Pods with Kyverno

🧠 Difficulty: Intermediate
🧩 Domain : Minimize Microservice Vulnerabilities
⏱️ Estimated Time: 10 minutes

🎯 Goal:  
Automatically mutate pods that do not have an `env` label by adding `env: prod`.

📌 Your mission:
1. Install Kyverno using Helm.
   - Installation guide: https://kyverno.io/docs/installation/methods/
2. Create a namespace called `autolabel`.
3. Create a Kyverno `ClusterPolicy` nammed `add-env-label` that:
   - Adds the label `env: prod` to any Pod in the namespace `autolabel` **if** the label `env` is missing.
   Mutation Guide Example : https://kyverno.io/docs/writing-policies/mutate/#add-if-not-present-anchor
4. Deploy:
   - 🔵 A pod **without** any label → it should automatically get `env: prod`.
   - 🔵 A pod **with** the label `env: staging` → it must **stay unchanged**.

✅ Expected result:
- Pods without `env` will have `env: prod` automatically.
- Pods already having an `env` label will **not** be mutated.

🧹 A `reset.sh` script is available to clean the cluster between attempts.
