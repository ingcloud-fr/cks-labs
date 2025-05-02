🛡️ Lab: Restrict Syscalls using Local Seccomp Profiles

🧠 Difficulty: Intermediate  
⏱️ Estimated Time: 15 minutes

🎯 Goal:  
Apply two different custom seccomp profiles that block dangerous syscalls (`unshare`, `ptrace`) to different pods on `controlplane01`.

📌 Your mission:

1. Two profiles are placed under `/home/vagrant/profile/`:
   - `seccomp-deny-unshare.json`
   - `seccomp-deny-ptrace.json`
2. Install the 2 seccomp profiles on both `controlplane01` and `node01` (depends on your cluster it might be `k8s-controlplane01` and `k8s-node01`)
3. Create a pod named `pod-unshare` with image `ubuntu` in the namespace `team-blue` (already created) that:
   - runs the command `unshare --mount --pid --fork --mount-proc bash` and uses the profile `seccomp-deny-unshare.json` that blocks it
   - verify that `unshare` fails due to seccomp
4. Create another pod named `pod-unshare` with image `ubuntu` that sleep for 1 hour and uses the profile `seccomp-deny-ptrace.json`:
   - runs a sheel bash in it
   - install the package `strace`
   - verify that `strace ls` fails due to seccomp

✅ Expected:
- The first pod will fail to execute `unshare` with a `Permission denied` error
- The second pod will fail to execute `strace` with a `ptrace` error

🧹 A reset.sh script is provided to clean up the namespace and profiles.
