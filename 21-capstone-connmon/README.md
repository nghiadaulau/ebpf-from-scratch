# 21 — Capstone: write connmon, a node-wide TCP connection monitor

The final piece: assemble everything into a real tool. `connmon` prints every new
outgoing TCP connection on the node, live — using a **kprobe** (art 06) on `tcp_connect`,
a **ring buffer** (art 09), **CO-RE** (art 05), and a **Go loader** with cilium/ebpf
(art 10). ~100 lines, one static binary.

## How it works

- **Kernel** (`connmon.bpf.c`): `kprobe/tcp_connect` reads `struct sock *sk` via
  `BPF_CORE_READ` (dst ip/port, family), pushes an event over a ring buffer.
- **Userspace** (`main.go`): `bpf2go` embeds the object + generates bindings;
  `link.Kprobe` attaches; `ringbuf.Reader` streams events; prints them live.

## Build & run

```bash
go generate          # bpf2go: clang compile + embed + bindings
go build -o connmon .
sudo ./connmon
```
```text
TIME         COMM             PID     SADDR           -> DADDR:PORT
03:39:44.082 kubelet          817     10.200.0.64     -> 10.200.0.180:9808
03:39:44.093 curl             7812    10.0.1.20       -> 10.0.1.10:6443     # apiserver via LB
03:39:43.301 coredns          2555    127.0.0.1       -> 127.0.0.1:8080
```

## Build gotcha: kprobe needs the target arch

First `go generate` fails with:

```text
GCC error "The eBPF is using target specific macros, please provide -target ..."
```

`BPF_KPROBE` reads args from `pt_regs`, whose layout is **arch-specific**, so
`bpf_tracing.h` needs `__TARGET_ARCH_x86`. Tracepoints (art 09-10) don't touch
`pt_regs` so they don't hit this. Fix: add `-D__TARGET_ARCH_x86` to the bpf2go cflags
(see the `//go:generate` line in `main.go`).

## Cleanup

`connmon` removes the kprobe + ring buffer on exit (Ctrl+C); the node returns to its
baseline program count.

---

This is a miniature `tcpconnect` — the same kind of tool Cilium / Pixie / Falco build at
scale. It closes the **eBPF Từ Số Không** series: from the VM and verifier to writing
your own production-style observability tool in both C and Go.
