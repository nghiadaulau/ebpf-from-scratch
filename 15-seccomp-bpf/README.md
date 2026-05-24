# 15 — seccomp-bpf: classic BPF syscall filtering, in every container

Before eBPF there was **cBPF** (classic Berkeley Packet Filter — what tcpdump uses).
And it's still running: **seccomp-bpf** filters syscalls with **cBPF**, not eBPF. The
kernel translates the cBPF to eBPF internally, but the userspace API is classic BPF
(`struct sock_filter` arrays). seccomp is the most widely deployed BPF on earth.

## cBPF vs eBPF

- **cBPF**: 2 registers (A, X), tiny instruction set, no maps, no helpers, no loops.
- **eBPF**: 11 64-bit registers, maps, helpers, verifier. (See article 01.)

## Real seccomp on the cluster

```bash
# processes with Seccomp: 2 (filter mode)
for p in /proc/[0-9]*; do grep -q '^Seccomp:.2' $p/status 2>/dev/null && echo $p; done
```

- `pause` (pod sandbox), `csi-*`, `cilium-operator` → `filters=1` (containerd default profile)
- privileged pods (`cilium-agent`, `kubelet`) → `Seccomp: 0` (**unconfined** — not every
  container has seccomp; k8s only applies it with `seccompProfile: RuntimeDefault`)
- `systemd-resolve` → **28 filters** stacked (filters can't be removed)

## Our own filter (`seccomp_demo.c`)

8 cBPF instructions over `struct seccomp_data` (syscall `nr`, `arch`, `args`):
check arch is x86_64, deny `mkdir`/`mkdirat` with `SECCOMP_RET_ERRNO | EPERM`, allow
the rest. Installed with `prctl(PR_SET_SECCOMP, SECCOMP_MODE_FILTER, &prog)` after
`prctl(PR_SET_NO_NEW_PRIVS, 1, ...)`.

```bash
gcc seccomp_demo.c -o seccomp_demo && ./seccomp_demo
```
```text
before filter: mkdir /tmp/sc-a -> OK
seccomp filter installed (mode 2)
after filter:  mkdir /tmp/sc-b -> Operation not permitted
after filter:  this printf still works (write syscall allowed)
```

## seccomp vs LSM BPF (article 14)

| | seccomp-bpf | LSM BPF |
|---|---|---|
| BPF | cBPF | eBPF |
| Filters on | raw syscall nr + args | semantic operations (open *this file*) |
| Sees | `seccomp_data` | real kernel objects (`struct file *`) |
| Scope | per-process, inherited across fork | system-wide |
| Removable | no (stacks until exit) | yes (detach link) |

seccomp narrows the *syscall surface* (fast, but pointer-blind); LSM BPF enforces
*semantic policy*. They complement each other.

## Cleanup

Nothing system-wide: a seccomp filter lives only inside the demo process and vanishes
when it exits. The `/proc` scan is read-only.
