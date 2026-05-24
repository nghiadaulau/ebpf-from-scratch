# 02 — The verifier: why eBPF can't crash the kernel

Article (Vietnamese): https://kkloudtarus.net/blog/verifier-ebpf

Demonstrates the eBPF verifier rejecting an unsafe program and accepting a fixed one.

- `xdp_bad.bpf.c`  — reads a packet byte with NO `data_end` bounds check → verifier rejects.
- `xdp_good.bpf.c` — same read, bounds-checked → verifier accepts.
- `make` to build; `commands.sh` for the load/inspect steps.

Needs `clang` + `libbpf-dev` on the node (`apt install clang libbpf-dev`).
