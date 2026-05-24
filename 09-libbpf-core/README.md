# 09 — libbpf + CO-RE: writing a real eBPF tool

Article (Vietnamese): https://kkloudtarus.net/blog/libbpf-co-re

`execsnoop`: a libbpf + CO-RE tool that streams every `exec()` (comm, pid, ppid,
filename) via a ring buffer.

- `exec.h`      — event struct shared by kernel + userspace.
- `exec.bpf.c`  — kernel program: tracepoint on exec -> ring buffer.
- `exec.c`      — userspace loader: skeleton + libbpf + ring_buffer poll.
- `make` (generates vmlinux.h + skeleton + links libbpf); `sudo ./execsnoop` to run.

Needs `clang`, `libbpf-dev`, `bpftool`.
