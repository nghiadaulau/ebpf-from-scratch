#!/usr/bin/env bash
# Inspect the eBPF VM via a live program's bytecode (read-only). Run on a node.
set -euo pipefail

# Post-verifier eBPF bytecode of program id 903 (a cgroup_device prog).
# Shows registers r0-r5, LDX/ALU/JMP instruction classes, opcodes, relative jumps.
sudo bpftool prog dump xlated id 903

# JIT proof: bytecode size vs native machine code size + JIT enabled flag.
sudo bpftool prog show id 903 | grep -oE 'xlated [0-9]+B|jited [0-9]+B'
cat /proc/sys/net/core/bpf_jit_enable

# Note: this node's bpftool lacks JIT disassembly (no libbfd); only sizes are shown.
