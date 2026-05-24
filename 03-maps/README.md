# 03 — Maps: memory and the bridge to userspace

Article (Vietnamese): https://kkloudtarus.net/blog/ebpf-maps

`count_exec.bpf.c` — a tracepoint program that counts process `exec` events into a
BPF array map. The kernel program writes the map; userspace reads it with bpftool,
showing the full kernel↔userspace map lifecycle.

- `make` to build; `commands.sh` to load (autoattach), trigger, and read the counter.
