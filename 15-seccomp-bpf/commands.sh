#!/usr/bin/env bash
# seccomp-bpf: syscall filtering with CLASSIC BPF (cBPF) — not eBPF.

# 1. See which processes are seccomp-confined (Seccomp: 2 = filter mode)
for p in $(ls /proc | grep -E '^[0-9]+$'); do
  s=$(grep -m1 '^Seccomp:' /proc/$p/status 2>/dev/null | awk '{print $2}')
  [ "$s" = "2" ] && echo "pid $p $(cat /proc/$p/comm) filters=$(grep -m1 Seccomp_filters /proc/$p/status | awk '{print $2}')"
done | sort -u
# Note: pause/CSI containers -> filters=1 (containerd default profile);
#       privileged pods (cilium-agent, kubelet) -> Seccomp: 0 (unconfined);
#       systemd-resolve -> many stacked filters (can't be removed).

# 2. Build + run our own cBPF filter (denies mkdir with EPERM)
gcc seccomp_demo.c -o seccomp_demo
./seccomp_demo        # mkdir -> Operation not permitted; printf still works
rm -f seccomp_demo
