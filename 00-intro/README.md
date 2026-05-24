# 00 — What eBPF is and how it runs

Article (Vietnamese): https://kkloudtarus.net/blog/gioi-thieu-ebpf

Intro to the series. No program to build yet — we only *inspect* the eBPF programs
that Cilium already runs in the kernel, to make the concepts concrete.

- `commands.sh` — `bpftool` commands used to dissect the live BPF programs/maps
  on a cluster node (read-only).
