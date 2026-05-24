#!/usr/bin/env bash
# Inspect the eBPF programs/maps Cilium already runs in the kernel (read-only).
# Run on a cluster node (kernel 6.17, bpftool preinstalled).
set -euo pipefail

# Count loaded programs and maps
sudo bpftool prog show | grep -c '^[0-9]*:'
sudo bpftool map show  | grep -c '^[0-9]*:'

# Programs by type (sched_cls = tc datapath, cgroup_* = device/sock control)
sudo bpftool prog show | grep -oE '^[0-9]+: [a-z_]+' | awk '{print $2}' | sort | uniq -c | sort -rn

# Anatomy of one program: xlated (verified bytecode), jited (native), maps, BTF
sudo bpftool prog show name tail_no_service_ipv4

# Maps holding state for those programs
sudo bpftool map show | grep -i cilium

# JIT enabled system-wide
cat /proc/sys/net/core/bpf_jit_enable
