#!/usr/bin/env bash
set -uo pipefail
# uprobe: who is resolving which hostname (userspace libc function)
sudo bpftrace dns_lookups.bt

# USDT probes baked into libc
sudo bpftrace -l 'usdt:/usr/lib/x86_64-linux-gnu/libc.so.6:*' | head

# Observe a pod from the host: count its syscalls by name (no sidecar, no pod change)
cpid=$(pgrep -x cilium-agent | head -1)
sudo bpftrace -e "tracepoint:syscalls:sys_enter_* /pid == $cpid/ { @[probe] = count(); }"
