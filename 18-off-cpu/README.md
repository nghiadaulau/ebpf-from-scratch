# 18 — Off-CPU & scheduler latency: measure time a process is NOT running

On-CPU profiling (article 17) shows where CPU burns. But most latency is time the
process is **off-CPU**: waiting for disk, network, a lock, or a CPU slot. On-CPU
sampling can't see it (the task isn't running). Scheduler tracepoints can.

## Two distinct questions

1. **Run-queue latency** — task is *ready* (woken) but waits for a free CPU. This is
   scheduler / CPU-contention delay. (`runqlat.bt`)
2. **Off-CPU time** — task *yielded* to wait for an event (I/O, lock, sleep). This is
   blocked time. (`offcputime.bt`)

Both read `sched_wakeup` and `sched_switch` tracepoints.

## Run

```bash
./commands.sh
```

### Run-queue latency (µs), under 4 busy tasks on 2 CPUs

```text
[4, 8)     5787 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|  # most: 4-8µs
[16, 32)    355 |@@@                                                |
[16K, 32K)    2 |                                                   |  # tail: 16-32ms = contention
```

### Off-CPU time (ms)

```text
[0]      22137 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|  # most: brief switches
[8, 16)   1248 |@@                                                 |
[4K, 8K)     4 |                                                   |  # tail: 4-8 SECONDS blocked
```

The `[0]` bucket dominates (most context switches are instant) — the **tail** is what
matters. Key the off-CPU timestamp by `kstack` to learn *where* a task blocks.

## Why it's cheap

These hooks are scheduler tracepoints that already fire on every context switch. The
eBPF program just stores a timestamp and adds to an in-kernel histogram — no events
pushed to userspace — so it's safe on production. (These are BCC's `runqlat` /
`offcputime`.)

On-CPU (17) + off-CPU (18) = the full performance picture.
