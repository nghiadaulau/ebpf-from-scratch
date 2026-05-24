#!/usr/bin/env bash
# Show the verifier rejecting an unsafe program, then accepting the fixed one.
set -uo pipefail
make

echo "## unsafe program -> verifier REJECTS (-EACCES + log)"
sudo bpftool prog load xdp_bad.bpf.o /sys/fs/bpf/xdp_bad   # prints the verifier log

echo "## safe program -> verifier ACCEPTS"
sudo bpftool prog load xdp_good.bpf.o /sys/fs/bpf/xdp_good
sudo bpftool prog dump xlated pinned /sys/fs/bpf/xdp_good  # see the bounds-check JMP

# cleanup: unpin -> frees the programs
sudo rm -f /sys/fs/bpf/xdp_good /sys/fs/bpf/xdp_bad
