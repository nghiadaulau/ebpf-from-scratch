//go:build ignore
// connmon: trace every new outgoing TCP connection (kprobe on tcp_connect),
// push {pid, comm, dst ip:port} to userspace via a ring buffer.
#include "vmlinux.h"
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_core_read.h>
#include <bpf/bpf_tracing.h>
#include <bpf/bpf_endian.h>

#define AF_INET 2

char LICENSE[] SEC("license") = "GPL";

struct event {
	__u32 pid;
	__u32 saddr;     // __be32 (network order)
	__u32 daddr;     // __be32
	__u16 dport;     // host order
	__u16 af;
	char  comm[16];
};

struct {
	__uint(type, BPF_MAP_TYPE_RINGBUF);
	__uint(max_entries, 256 * 1024);
} events SEC(".maps");

SEC("kprobe/tcp_connect")
int BPF_KPROBE(trace_tcp_connect, struct sock *sk)
{
	__u16 family = BPF_CORE_READ(sk, __sk_common.skc_family);
	if (family != AF_INET)
		return 0;                                   // IPv4 only, keep it small

	struct event *e = bpf_ringbuf_reserve(&events, sizeof(*e), 0);
	if (!e)
		return 0;
	e->pid   = bpf_get_current_pid_tgid() >> 32;
	e->af    = family;
	e->saddr = BPF_CORE_READ(sk, __sk_common.skc_rcv_saddr);
	e->daddr = BPF_CORE_READ(sk, __sk_common.skc_daddr);
	e->dport = bpf_ntohs(BPF_CORE_READ(sk, __sk_common.skc_dport));
	bpf_get_current_comm(&e->comm, sizeof(e->comm));
	bpf_ringbuf_submit(e, 0);
	return 0;
}
