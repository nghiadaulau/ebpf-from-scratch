#!/usr/bin/env bash
# Write-your-own tc/sched_cls: count + classify egress packets by L3 protocol.
# Attached on `lo` (loopback) so it's the only program in the tcx chain — see why below.
set -e
IFACE=${1:-lo}
[ -f vmlinux.h ] || sudo bpftool btf dump file /sys/kernel/btf/vmlinux format c > vmlinux.h
clang -O2 -g -target bpf -I. -c count.bpf.c -o count.bpf.o
sudo rm -rf /sys/fs/bpf/tccount 2>/dev/null || true
sudo bpftool prog loadall count.bpf.o /sys/fs/bpf/tccount

trap 'sudo bpftool net detach tcx_egress dev $IFACE 2>/dev/null; sudo rm -rf /sys/fs/bpf/tccount' EXIT

# tcx attach (kernel 6.6+). bpftool shows it as tcx/egress.
sudo bpftool net attach tcx_egress pinned /sys/fs/bpf/tccount/count_egress dev "$IFACE"
sudo bpftool net show dev "$IFACE"

# generate a little loopback traffic
ping  -c 3 -W 1 127.0.0.1 >/dev/null 2>&1 || true
ping6 -c 2 -W 1 ::1       >/dev/null 2>&1 || true

# read counts (pick OUR map by exact name, not cilium_egress*)
MID=$(sudo bpftool map show | awk '$3=="name" && $4=="egress"{print $1}' | tr -d ':')
echo "counts: 0=total 1=IPv4 2=IPv6 3=other 9=bytes"
sudo bpftool map dump id "$MID"
