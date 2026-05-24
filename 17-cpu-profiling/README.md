# 17 — CPU profiling with perf_event: stack sampling, the basis of flame graphs

Profiling doesn't measure every call — it **samples statistically**. Tens/hundreds of
times per second, freeze each CPU and record the running stack. A function appearing in
many samples is burning CPU time.

## Mechanism

A `perf_event` eBPF program is attached to the kernel's CPU-clock counter
(`PERF_COUNT_SW_CPU_CLOCK`). Each time it fires (here 99 Hz, per CPU), the program runs
in interrupt context, captures the stack with `bpf_get_stackid` into a stack map, and
aggregates `count()` — all in-kernel. Userspace just reads the counted stacks.

## Run

```bash
./commands.sh
```

### Hot kernel stacks (a `dd if=/dev/zero` load)

```text
@[ rep_stos_alternative+75 ; vfs_read+186 ; ksys_read+113 ;
   __x64_sys_read+25 ; do_syscall_64+128 ; entry_SYSCALL_64... ]: 95   # dd reading /dev/zero
@[ pv_native_safe_halt+11 ; arch_cpu_idle+9 ; default_idle_call+48 ;
   do_idle+127 ; cpu_startup_entry+41 ; start_secondary+296 ]: 383     # idle loop
```

### Per-process (who is on-CPU)

```text
@samples[dd]:        479      # the load
@samples[swapper/0]: 237      # CPU 0 idle  (swapper/N = idle task of CPU N)
@samples[swapper/1]: 215      # CPU 1 idle
@samples[kubelet]:    11
```

## Why 99 Hz, not 100?

A prime number avoids lock-step with the kernel's periodic 100 Hz timer tick, which
would otherwise bias the samples. (Brendan Gregg's classic trick.)

## It really is eBPF

```text
during profiling: 141 progs; perf_event progs: 1
after:            140 progs
```

## Flame graphs

`@[kstack] = count()` is exactly the input a flame graph needs: fold each stack to
`a;b;c <count>`, render with `flamegraph.pl`. Because aggregation happens in-kernel,
you can profile production continuously — the basis of Parca / Pyroscope.
