# 16 — Tetragon-style: from observation to enforcement with bpf_send_signal

**Tetragon** (a Cilium project) does runtime security by attaching to the same
*observation* hooks as Part II (kprobe/tracepoint), then *acting*. Per the Tetragon
docs, it enforces two ways, both eBPF helpers running in-kernel (no userspace round-trip):

1. **`bpf_send_signal()`** — send a signal (usually `SIGKILL`) to the matching process,
   killing it synchronously.
2. **`bpf_override_return()`** — override a function/syscall return value (e.g. force
   `openat` to return `-EPERM`), blocking the operation without killing the process.

## What we build

`tetra_kill.bpf.c` is `execsnoop` (article 09) with one line changed: instead of
reporting the exec, it calls `bpf_send_signal(9)` if the exec'd file is exactly
`/tmp/forbidden-bin`. Observation → enforcement in one helper call.

## Run

```bash
./commands.sh
```
```text
-- normal /bin/sleep 0.2 --
  OK (exit 0)
-- /tmp/forbidden-bin 5 --
  Killed
  exit=137         # 128 + SIGKILL, killed at exec
```

## Important: SIGKILL alone isn't always enough

The Tetragon docs note that a synchronous SIGKILL stops the process but does **not**
always prevent the in-flight operation (e.g. a SIGKILL during `write()` doesn't
guarantee the data wasn't written). To *guarantee* a block, combine `bpf_send_signal`
with `bpf_override_return`. Killing at `exec` (this demo) is fine — the process dies
before doing anything.

(This node has `CONFIG_BPF_KPROBE_OVERRIDE=y` + `CONFIG_FUNCTION_ERROR_INJECTION=y`, so
`bpf_override_return` works — but only on functions marked `ALLOW_ERROR_INJECTION`.)

## Why no reboot (vs article 14 LSM)

This attaches to a **tracepoint** and enforces via a **signal**, so it needs neither
`bpf` in the active LSM list nor a reboot — it runs on any stock kernel with
`bpf_send_signal` (since 5.3). The trade-off: it enforces *after* the event starts
(kills the running/exec'd process) rather than blocking *before* like LSM.

## Cleanup

```bash
sudo rm -rf /sys/fs/bpf/tetra
```
