#!/usr/bin/env bash
# bpftrace one-liners. Run on a node (bpftrace preinstalled).
set -uo pipefail

# Proof: a bpftrace one-liner loads/unloads a real eBPF program (watch the count)
sudo bpftool prog show | grep -c '^[0-9]*:'
sudo bpftrace -e 'tracepoint:syscalls:sys_enter_openat { @ = count(); }' &
sleep 2; sudo bpftool prog show | grep -c '^[0-9]*:'; kill %1 2>/dev/null

# Which process opens which file (probe / action, built-in comm, str(args.filename))
sudo bpftrace -e 'tracepoint:syscalls:sys_enter_openat { printf("%-16s %s\n", comm, str(args.filename)); }'

# The probe universe
sudo bpftrace -l | wc -l
sudo bpftrace -l | sed 's/:.*//' | sort | uniq -c | sort -rn

# Filter (predicate): only opens by `cat`
sudo bpftrace -e 'tracepoint:syscalls:sys_enter_openat /comm == "cat"/ { printf("%s opened %s\n", comm, str(args.filename)); }'
