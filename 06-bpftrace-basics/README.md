# 06 — bpftrace basics: tracing in one line

Article (Vietnamese): https://kkloudtarus.net/blog/bpftrace-co-ban

bpftrace is a high-level tracing language that compiles to eBPF and loads it (no C,
no clang). Syntax: `probe /filter/ { action }`. These one-liners run on a node.

- `commands.sh` — prove bpftrace loads an eBPF program; trace openat; list probes; filter.
