#!/usr/bin/env bash
# CPU profiling with a perf_event eBPF program (via bpftrace's profile probe).
# Why 99 Hz (not 100)? A prime avoids lock-step with the kernel's 100 Hz timer tick.

# generate some load to see
( timeout 6 bash -c 'while :; do dd if=/dev/zero of=/dev/null bs=1M count=2000 2>/dev/null; done' ) &

# hot kernel stacks
sudo timeout 6 bpftrace -e 'profile:hz:99 { @[kstack] = count(); }'

# who is on-CPU (swapper/N = idle on CPU N)
sudo timeout 6 bpftrace -e 'profile:hz:99 { @samples[comm] = count(); }'

# proof it's eBPF: a perf_event program appears while profiling, gone after
# sudo bpftool prog show | grep -c perf_event
wait 2>/dev/null
