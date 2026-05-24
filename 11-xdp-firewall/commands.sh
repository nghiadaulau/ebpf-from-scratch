#!/usr/bin/env bash
# XDP firewall: drop ICMP, pass everything else. Attach to a real interface.
# SAFE on a remote host: SSH is TCP, so dropping ICMP won't cut your session.
set -e
IFACE=${1:-ens5}

# 1. vmlinux.h for CO-RE (reuse if present)
[ -f vmlinux.h ] || sudo bpftool btf dump file /sys/kernel/btf/vmlinux format c > vmlinux.h

# 2. compile to eBPF bytecode
clang -O2 -g -target bpf -I. -c xdp_fw.bpf.c -o xdp_fw.bpf.o

# 3. load + pin program and map
sudo rm -rf /sys/fs/bpf/xdpfw 2>/dev/null || true
sudo bpftool prog loadall xdp_fw.bpf.o /sys/fs/bpf/xdpfw

# ALWAYS detach on exit (don't leave a packet filter attached)
trap 'sudo bpftool net detach xdpgeneric dev $IFACE 2>/dev/null; sudo rm -rf /sys/fs/bpf/xdpfw' EXIT

# 4. attach in generic mode (safe to test, easy to detach)
sudo bpftool net attach xdpgeneric pinned /sys/fs/bpf/xdpfw/xdp_fw dev $IFACE
sudo bpftool net show dev $IFACE

# 5. test: ICMP now dropped (echo-reply vanishes on ingress), TCP/SSH still works
ping -c 4 -W 2 10.0.1.10 || true

# 6. read the drop counter
MID=$(sudo bpftool map show | awk '/icmp_drops/{print $1}' | tr -d ':')
sudo bpftool map dump id "$MID"
