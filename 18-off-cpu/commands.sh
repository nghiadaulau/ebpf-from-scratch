#!/usr/bin/env bash
# Off-CPU analysis: where the time goes when a process is NOT running.

# 1. run-queue latency (needs CPU contention to be interesting)
for i in $(seq 1 $(( $(nproc) * 2 ))); do timeout 8 bash -c 'while :; do :; done' & done
sudo timeout 6 bpftrace runqlat.bt

# 2. off-CPU time (blocked/waiting durations)
( timeout 8 bash -c 'while :; do dd if=/dev/zero of=/tmp/ocpu bs=1M count=50 conv=fsync 2>/dev/null; sleep 0.05; done' ) &
sudo timeout 6 bpftrace offcputime.bt
wait 2>/dev/null; rm -f /tmp/ocpu
