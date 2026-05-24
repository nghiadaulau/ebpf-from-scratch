# 08 — uprobe, USDT, and observing a pod from the host

Article (Vietnamese): https://kkloudtarus.net/blog/uprobe-usdt-soi-pod

eBPF reaches into userspace (uprobe = any function in a binary/library; USDT =
static probes apps ship). And since a container is just a host process, eBPF on the
host kernel can observe any pod by filtering on its PID/cgroup — no sidecar needed.

- `dns_lookups.bt` — uprobe on libc `getaddrinfo`, prints comm + hostname.
- `commands.sh` — uprobe demo, list libc USDT, trace a pod's syscalls from the host.
