# ✅ Solution – Syscall detection with Falco

## On node01

```
vagrant@k8s-node01:/etc/falco$ sudo falco -U
Mon Apr 14 18:09:43 2025: Falco version: 0.40.0 (x86_64)
Mon Apr 14 18:09:43 2025: Falco initialized with configuration files:
Mon Apr 14 18:09:43 2025:    /etc/falco/config.d/engine-kind-falcoctl.yaml | schema validation: ok
Mon Apr 14 18:09:43 2025:    /etc/falco/falco.yaml | schema validation: ok
Mon Apr 14 18:09:43 2025: System info: Linux version 5.15.0-136-generic (buildd@lcy02-amd64-034) (gcc (Ubuntu 11.4.0-1ubuntu1~22.04) 11.4.0, GNU ld (GNU Binutils for Ubuntu) 2.38) #147-Ubuntu SMP Sat Mar 15 15:53:30 UTC 2025
Mon Apr 14 18:09:43 2025: Loading rules from:
Mon Apr 14 18:09:43 2025:    /etc/falco/falco_rules.yaml | schema validation: ok
Mon Apr 14 18:09:43 2025:    /etc/falco/falco_rules.local.yaml | schema validation: ok
Mon Apr 14 18:09:43 2025: The chosen syscall buffer dimension is: 8388608 bytes (8 MBs)
Mon Apr 14 18:09:43 2025: you required a buffer every '2' CPUs but there are only '1' online CPUs. Falco changed the config to: one buffer every '1' CPUs
Mon Apr 14 18:09:43 2025: Starting health webserver with threadiness 1, listening on 0.0.0.0:8765
Mon Apr 14 18:09:43 2025: Loaded event sources: syscall
Mon Apr 14 18:09:43 2025: Enabled event sources: syscall
Mon Apr 14 18:09:43 2025: Opening 'syscall' source with modern BPF probe.
Mon Apr 14 18:09:43 2025: One ring buffer every '1' CPUs.
18:09:50.240572630: Warning Sensitive file opened for reading by non-trusted program (file=/etc/shadow gparent=containerd-shim ggparent=systemd gggparent=<NA> evt_type=openat user=root user_uid=0 user_loginuid=-1 process=cat proc_exepath=/usr/bin/cat parent=sh command=cat /etc/shadow terminal=0 container_id=84bf4e3e6def container_name=app)
18:10:00.243120564: Warning Sensitive file opened for reading by non-trusted program (file=/etc/shadow gparent=containerd-shim ggparent=systemd gggparent=<NA> evt_type=openat user=root user_uid=0 user_loginuid=-1 process=cat proc_exepath=/usr/bin/cat parent=sh command=cat /etc/shadow terminal=0 container_id=84bf4e3e6def container_name=app)
```

We look for the pod/deploy :

```
vagrant@k8s-node01:/etc/falco$ sudo crictl ps -id 84bf4e3e6def
CONTAINER           IMAGE               CREATED             STATE               NAME                ATTEMPT             POD ID              POD                      NAMESPACE
84bf4e3e6def7       595d99e62673e       16 minutes ago      Running             app                 0                   00d3fa82f5431       app-b-748f977994-6sxp7   team-blue

vagrant@k8s-node01:/etc/falco$ sudo crictl pods -id 00d3fa82f5431
POD ID              CREATED             STATE               NAME                     NAMESPACE           ATTEMPT             RUNTIME
00d3fa82f5431       17 minutes ago      Ready               app-b-748f977994-6sxp7   team-blue           0                   (default)
```

We can scale down to 0 the application :

```
vagrant@k8s-node01:/etc/falco$ k -n team-blue scale deploy/app-b --replicas 0
deployment.apps/app-b scaled
```

## On the controlplane

```
vagrant@k8s-controlplane:~$ sudo falco -U
Mon Apr 14 17:56:56 2025: Falco version: 0.40.0 (x86_64)
Mon Apr 14 17:56:56 2025: Falco initialized with configuration files:
Mon Apr 14 17:56:56 2025:    /etc/falco/config.d/engine-kind-falcoctl.yaml | schema validation: ok
Mon Apr 14 17:56:56 2025:    /etc/falco/falco.yaml | schema validation: ok
Mon Apr 14 17:56:56 2025: System info: Linux version 5.15.0-136-generic (buildd@lcy02-amd64-034) (gcc (Ubuntu 11.4.0-1ubuntu1~22.04) 11.4.0, GNU ld (GNU Binutils for Ubuntu) 2.38) #147-Ubuntu SMP Sat Mar 15 15:53:30 UTC 2025
Mon Apr 14 17:56:56 2025: Loading rules from:
Mon Apr 14 17:56:56 2025:    /etc/falco/falco_rules.yaml | schema validation: ok
Mon Apr 14 17:56:56 2025:    /etc/falco/falco_rules.local.yaml | schema validation: ok
Mon Apr 14 17:56:56 2025: The chosen syscall buffer dimension is: 8388608 bytes (8 MBs)
Mon Apr 14 17:56:56 2025: Starting health webserver with threadiness 2, listening on 0.0.0.0:8765
Mon Apr 14 17:56:56 2025: Loaded event sources: syscall
Mon Apr 14 17:56:56 2025: Enabled event sources: syscall
Mon Apr 14 17:56:56 2025: Opening 'syscall' source with modern BPF probe.
Mon Apr 14 17:56:56 2025: One ring buffer every '2' CPUs.
17:57:00.311182688: Warning Package manager execution detected (container=c65a2ebf0573)
17:57:00.333215675: Warning Package manager execution detected (container=c65a2ebf0573)
17:57:00.496115376: Warning Package manager execution detected (container=c65a2ebf0573)
```

```
vagrant@k8s-controlplane:~$ sudo crictl ps -a | grep c65a2ebf0573
c65a2ebf05735       595d99e62673e       3 minutes ago       Running             app                       0                   659e26ab5e0d2       app-c-865bd44448-wpbkr                     team-red
```

Or : 

```
vagrant@k8s-controlplane:~$ sudo crictl ps -id c65a2ebf0573
CONTAINER           IMAGE               CREATED             STATE               NAME                ATTEMPT             POD ID              POD                      NAMESPACE
c65a2ebf05735       595d99e62673e       4 minutes ago       Running             app                 0                   659e26ab5e0d2       app-c-865bd44448-wpbkr   team-red
```

We can see the pod now :

```
vagrant@k8s-controlplane:~$ sudo crictl pods -id 659e26ab5e0d2
POD ID              CREATED             STATE               NAME                     NAMESPACE           ATTEMPT             RUNTIME
659e26ab5e0d2       5 minutes ago       Ready               app-c-865bd44448-wpbkr   team-red            0                   (default)
```

It belongs to `app-c` deployment in `team-red` namespace, but we do nothing for the moment. Before scale down the deploy, we have to change the rule.

When we start Falco, we can see :

```
Mon Apr 14 17:56:56 2025:    /etc/falco/falco_rules.yaml | schema validation: ok
Mon Apr 14 17:56:56 2025:    /etc/falco/falco_rules.local.yaml | schema validation: ok
```

The Package manager execution detected ruel is in one of these files:

```
vagrant@k8s-controlplane:~$ grep "Package manager execution detected" /etc/falco/falco_rules.*
/etc/falco/falco_rules.local.yaml:    Package manager execution detected (container=%container.id)
```

We can use the fields in documentation : https://falco.org/docs/reference/rules/supported-fields/

We edit the file `/etc/falco/falco_rules.local.yaml` and change the output and the priority to :

```yaml
- rule: Detect Package Management Execution
  desc: Detect execution of package management binaries (e.g. apt, dpkg)
  condition: spawned_process and proc.name in (package_mgmt_binaries)
  output: >
    Package manager execution detected (time=%evt.time.s user=%user.name command=%proc.cmdline container=%container.id container_name=%container.name image=%container.image.repository)
  priority: ALERT
  tags: [process, package_mgmt, suspicious]
```

We restart falco and execute it again :

```
vagrant@k8s-controlplane:~$ sudo systemctl restart falco

vagrant@k8s-controlplane:~$ sudo falco -U
...
18:29:54.647957722: Alert Package manager execution detected (time=18:29:54 user=root command=apt update container=c65a2ebf0573 container_name=app image=docker.io/library/debian)
18:29:54.659255233: Alert Package manager execution detected (time=18:29:54 user=root command=dpkg --print-foreign-architectures container=c65a2ebf0573 container_name=app image=docker.io/library/debian)
18:29:55.145001309: Alert Package manager execution detected (time=18:29:55 user=_apt command=apt-key /usr/bin/apt-key --quiet --readonly --keyring /usr/share/keyrings/debian-archive-keyring.gpg verify --status-fd 3 /tmp/apt.sig.2v54GU /tmp/apt.data.khoDPF container=c65a2ebf0573 container_name=app image=docker.io/library/debian)
18:29:55.151642803: Alert Package manager execution detected (time=18:29:55 user=_apt command=dpkg --print-foreign-architectures container=c65a2ebf0573 container_name=app image=docker.io/library/debian)
18:29:55.158530602: Alert Package manager execution detected (time=18:29:55 user=_apt command=dpkg --print-foreign-architectures container=c65a2ebf0573 container_name=app image=docker.io/library/debian)
```

The logs are ok now !

We can copy the local rule on node01 and restart Falco :

```
vagrant@k8s-controlplane:~$ scp /etc/falco/falco_rules.local.yaml root@k8s-node01:/etc/falco/

vagrant@k8s-controlplane:~$ ssh root@k8s-node01 systemctl restart falco
```

Now we can scale down the deployment we found previously (`app-c` deployment in `team-red` namespace):

```
vagrant@k8s-controlplane:~$ k -n team-red scale deploy/app-c --replicas 0
deployment.apps/app-c scaled
```


