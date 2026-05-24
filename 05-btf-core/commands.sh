#!/usr/bin/env bash
set -uo pipefail
ls -la /sys/kernel/btf/vmlinux              # the kernel's own BTF (~7MB)
make                                        # generates vmlinux.h + compiles ppid.bpf.o

sudo bpftool prog loadall ppid.bpf.o /sys/fs/bpf/ppid autoattach
sudo timeout 2 cat /sys/kernel/debug/tracing/trace_pipe | grep 'exec .* ppid='
sudo rm -rf /sys/fs/bpf/ppid
