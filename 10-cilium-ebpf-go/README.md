# 10 — cilium/ebpf: loading eBPF from Go

Article (Vietnamese): https://kkloudtarus.net/blog/cilium-ebpf-go

The same execsnoop as 09, but the userspace loader is Go using `cilium/ebpf` — how
the Kubernetes ecosystem (Cilium, Tetragon, Falco) builds eBPF tools. bpf2go embeds
the compiled object into Go and generates typed bindings; the result is a single
static binary (no libbpf.so, no separate .o to ship).

- `exec.bpf.c` — kernel program (unchanged from 09; has `//go:build ignore`).
- `exec.h`     — event struct.
- `main.go`    — Go loader: link.Tracepoint + ringbuf.Reader.
- `go.mod`/`go.sum` — module (cilium/ebpf v0.21).

Build (needs clang, llvm, bpftool, Go 1.21+):

    go generate    # bpf2go: compile exec.bpf.c + generate exec_bpfel.go (+ object)
    go build -o execsnoop-go .
    sudo ./execsnoop-go
