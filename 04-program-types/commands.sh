#!/usr/bin/env bash
set -uo pipefail
make
# Program types the kernel supports
sudo bpftool feature probe | grep 'program_type .* is available'
# Load the openat tracepoint and watch it fire system-wide
sudo bpftool prog loadall openat_trace.bpf.o /sys/fs/bpf/openat autoattach
sudo timeout 2 cat /sys/kernel/debug/tracing/trace_pipe | grep 'openat by'
sudo rm -rf /sys/fs/bpf/openat
