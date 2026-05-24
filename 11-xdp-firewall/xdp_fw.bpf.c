// A tiny XDP firewall: drop ICMP, pass everything else. Counts drops in a map.
// SAFE on a remote host: SSH is TCP, so dropping ICMP won't cut your session.
// Every memory read is bounds-checked (the verifier requires it — see article 02).
#include "vmlinux.h"
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_endian.h>

#define ETH_P_IP 0x0800

struct {
	__uint(type, BPF_MAP_TYPE_ARRAY);
	__uint(max_entries, 1);
	__type(key, __u32);
	__type(value, __u64);
} icmp_drops SEC(".maps");

SEC("xdp")
int xdp_fw(struct xdp_md *ctx)
{
	void *data     = (void *)(long)ctx->data;
	void *data_end = (void *)(long)ctx->data_end;

	struct ethhdr *eth = data;
	if ((void *)(eth + 1) > data_end)
		return XDP_PASS;
	if (eth->h_proto != bpf_htons(ETH_P_IP))
		return XDP_PASS;

	struct iphdr *ip = (void *)(eth + 1);
	if ((void *)(ip + 1) > data_end)
		return XDP_PASS;

	if (ip->protocol == IPPROTO_ICMP) {
		__u32 key = 0;
		__u64 *n = bpf_map_lookup_elem(&icmp_drops, &key);
		if (n)
			__sync_fetch_and_add(n, 1);
		return XDP_DROP;          // drop ICMP only
	}
	return XDP_PASS;                  // everything else (incl. SSH/TCP) passes
}

char LICENSE[] SEC("license") = "GPL";
