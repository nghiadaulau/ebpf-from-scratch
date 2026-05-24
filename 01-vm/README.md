# 01 — The eBPF virtual machine: registers, instructions, bytecode

Article (Vietnamese): https://kkloudtarus.net/blog/may-ao-ebpf

Reads the bytecode of a live Cilium program to see the eBPF VM: 11 64-bit registers
(r0 return, r1-r5 args/context, r6-r9 callee-saved, r10 read-only frame pointer),
8 instruction classes, JIT to native. Read-only inspection — no program built.

- `commands.sh` — dump xlated bytecode + size delta (bytecode vs JITed native).
