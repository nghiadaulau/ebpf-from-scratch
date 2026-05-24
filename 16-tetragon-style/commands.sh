#!/usr/bin/env bash
# Tetragon-style enforcement: observe with a tracepoint, then ACT with bpf_send_signal.
# Narrow + safe: only kills a process that exec's exactly /tmp/forbidden-bin.
set -e
[ -f vmlinux.h ] || sudo bpftool btf dump file /sys/kernel/btf/vmlinux format c > vmlinux.h
clang -O2 -g -target bpf -I. -c tetra_kill.bpf.c -o tetra_kill.bpf.o
sudo rm -rf /sys/fs/bpf/tetra 2>/dev/null || true
sudo bpftool prog loadall tetra_kill.bpf.o /sys/fs/bpf/tetra autoattach
trap 'sudo rm -rf /sys/fs/bpf/tetra; rm -f /tmp/forbidden-bin' EXIT

cp /bin/sleep /tmp/forbidden-bin
echo "-- normal /bin/sleep 0.2 --";   /bin/sleep 0.2 && echo "  OK (exit $?)"
echo "-- /tmp/forbidden-bin 5 (expect Killed, exit 137) --"; /tmp/forbidden-bin 5; echo "  exit=$?"
