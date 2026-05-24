# 04 — Program types and hooks

Article (Vietnamese): https://kkloudtarus.net/blog/program-types-va-hooks

A program type decides where a program attaches (hook), what context it gets, and
which helpers it may call. `openat_trace.bpf.c` is a `tracepoint` on `sys_enter_openat`
that prints comm+pid (from helpers) to trace_pipe on every file open.

- `make`; `commands.sh` to list supported types, load (autoattach), read trace_pipe.
