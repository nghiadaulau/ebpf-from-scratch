#!/usr/bin/env bash
# The eBPF program (kernel) writes a map; userspace reads it. Run on a node.
set -uo pipefail
make

# Inspect a real Cilium map (per-CPU metrics) for context
sudo bpftool map dump id 171 | head -4

# Load + auto-attach the exec counter
sudo bpftool prog loadall count_exec.bpf.o /sys/fs/bpf/cexec autoattach

# Read counter, trigger some execs, read again -> the value grows
sudo bpftool map dump name exec_count
for i in 1 2 3 4 5; do /bin/true; /bin/date >/dev/null; done
sudo bpftool map dump name exec_count

# cleanup: unpin frees the program and its map
sudo rm -rf /sys/fs/bpf/cexec
