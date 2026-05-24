# 05 — BTF and CO-RE: compile once, run on any kernel

Article (Vietnamese): https://kkloudtarus.net/blog/btf-va-co-re

`ppid.bpf.c` reads `task->real_parent->tgid` (parent PID) via `BPF_CORE_READ` — no
hardcoded offsets. libbpf relocates the field offsets at load time using the running
kernel's BTF, so the same object runs across kernel versions.

`vmlinux.h` is generated from `/sys/kernel/btf/vmlinux` (not committed):
`make` runs `bpftool btf dump file /sys/kernel/btf/vmlinux format c > vmlinux.h`.

- `make`; `commands.sh` to build, load (autoattach), watch ppid in trace_pipe.
