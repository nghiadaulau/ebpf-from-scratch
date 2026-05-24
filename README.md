# eBPF From Scratch

Hands-on source code (eBPF programs, loaders, scripts) accompanying the blog series
**"eBPF Từ Số Không"** — learning eBPF from the ground up, all the way to writing real
programs, using a live Kubernetes cluster (kernel 6.17, Cilium 1.19 eBPF) as the lab.

📖 **Read the series (Vietnamese):** https://kkloudtarus.net/blog/series/ebpf-tu-so-khong

## Roadmap (updated as the series progresses)

- **Part I — Foundations:** the eBPF VM, verifier, JIT, maps, program types, hooks
  (XDP/tc/kprobe/tracepoint/LSM/socket), BTF + CO-RE. Dissect the BPF that Cilium runs.
- **Part II — Tracing:** bpftrace (probes, maps, aggregations).
- **Part III — Writing programs:** libbpf + CO-RE (C), then a Go loader (cilium/ebpf).
- **Part IV — Networking:** XDP, tc, the Cilium datapath, LB / NetworkPolicy in BPF.
- **Part V — Security:** LSM BPF, seccomp-bpf, runtime enforcement.
- **Part VI — Observability:** profiling, latency histograms, Hubble internals.
- **Part VII — End-to-end Cilium case study + wrap-up.**

## Layout

Each `NN-*` directory maps to one article and contains the programs (`.bpf.c`, `.go`,
`.bt`), a `Makefile`/`commands.sh`, and a `README.md` linking to the post.

## Environment

Kernel **6.17.0-1015-aws** (BTF/CO-RE enabled), `bpftool` v7.7, `bpftrace`; the
clang/llvm + Go toolchain is set up in Part III. Everything is tested for real on the
cluster; sensitive values are masked.

## License
MIT
