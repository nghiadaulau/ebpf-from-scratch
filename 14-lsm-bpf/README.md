# 14 — LSM BPF: enforce a security decision in the kernel

Until now every eBPF program here only *observed*. **LSM BPF** *enforces*: it attaches
to the kernel's Linux Security Modules hooks — the same `security_*` hooks SELinux and
AppArmor use — and **the return value decides the operation**: `0` allows, a negative
errno like `-EPERM` denies.

`lsmtest.bpf.c` denies opening any file named exactly `lsm-secret` (returns `-EPERM`),
allows everything else.

## The catch: bpf must be an ACTIVE LSM

A BPF LSM program will **load and attach even when it can't enforce**. Enforcement only
happens if `bpf` is in the active LSM list:

```bash
cat /sys/kernel/security/lsm     # must contain "bpf"
```

Requirements (kernel ≥5.7): `CONFIG_BPF_LSM=y`, `CONFIG_DEBUG_INFO_BTF=y`, **and** bpf
enabled via `CONFIG_LSM="...,bpf"` or the `lsm=` boot parameter. To enable at boot:

```bash
# /etc/default/grub  — keep existing LSMs, append bpf
GRUB_CMDLINE_LINUX="lsm=landlock,lockdown,yama,integrity,apparmor,bpf"
sudo update-grub && sudo reboot
```

(Reboot keeps the host's IP; only `/tmp` is cleared, so recompile after.)

## Run

```bash
./commands.sh
```

- **bpf NOT active**: attaches, `cat` still reads the file (no enforcement).
- **bpf active**: `cat` → `Operation not permitted`; `python3` open() blocked too (the
  block is at the kernel hook, not tool-specific); a differently-named file still opens.

The attachment shows as `attach_type lsm_mac` (Mandatory Access Control).

## Key points

- `SEC("lsm/file_open")` + libbpf's `BPF_PROG(deny_open, struct file *file, int ret)`.
- **Respect prior verdicts**: `if (ret != 0) return ret;` — don't re-allow what another
  LSM already denied.
- Read the filename with CO-RE: `BPF_CORE_READ(file, f_path.dentry, d_name.name)`.

## Cleanup (mandatory)

```bash
sudo rm -rf /sys/fs/bpf/lsmtest    # unpin -> link released -> detaches immediately
```
