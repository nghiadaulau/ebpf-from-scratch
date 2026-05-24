#!/usr/bin/env bash
# LSM BPF: enforce a security decision in the kernel. Deny opening a file
# named exactly "lsm-secret"; allow everything else.
#
# REQUIREMENT: bpf must be an ACTIVE LSM, else the program loads & attaches but
# does NOT enforce. Check:  cat /sys/kernel/security/lsm   (must contain "bpf")
# Enable (needs reboot): add bpf to GRUB_CMDLINE_LINUX, e.g.
#   GRUB_CMDLINE_LINUX="lsm=landlock,lockdown,yama,integrity,apparmor,bpf"
#   sudo update-grub && sudo reboot
set -e
[ -f vmlinux.h ] || sudo bpftool btf dump file /sys/kernel/btf/vmlinux format c > vmlinux.h
clang -O2 -g -target bpf -I. -c lsmtest.bpf.c -o lsmtest.bpf.o

echo "active LSMs: $(cat /sys/kernel/security/lsm)"
grep -q bpf /sys/kernel/security/lsm || echo "WARNING: bpf not active -> will attach but NOT enforce"

echo secret > /tmp/lsm-secret
sudo rm -rf /sys/fs/bpf/lsmtest 2>/dev/null || true
sudo bpftool prog loadall lsmtest.bpf.o /sys/fs/bpf/lsmtest autoattach
trap 'sudo rm -rf /sys/fs/bpf/lsmtest; rm -f /tmp/lsm-secret /tmp/lsm-other' EXIT

echo "-- cat /tmp/lsm-secret (Operation not permitted if enforcing) --"
cat /tmp/lsm-secret || true
echo "-- a differently-named file still opens --"
echo ok > /tmp/lsm-other && cat /tmp/lsm-other
echo "-- python open() is blocked too (kernel-level, not tool-level) --"
python3 -c "open('/tmp/lsm-secret').read()" 2>&1 | tail -1 || true
sudo bpftool link show | grep -A2 lsm || true
