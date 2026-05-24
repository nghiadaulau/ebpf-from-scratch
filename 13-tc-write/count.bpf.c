// A tc/sched_cls program on EGRESS: count + classify packets by L3 protocol.
// The point vs XDP: tc hands you __sk_buff with metadata already filled in
// (skb->protocol, skb->len) — no raw header parsing needed. Never drops.
#include "vmlinux.h"
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_endian.h>

#define ETH_P_IP   0x0800
#define ETH_P_IPV6 0x86DD
#define TC_ACT_OK  0          // == TCX_PASS: pass the packet, STOP the tcx chain

// 0=total 1=IPv4 2=IPv6 3=other ; 9=total bytes
struct {
	__uint(type, BPF_MAP_TYPE_ARRAY);
	__uint(max_entries, 10);
	__type(key, __u32);
	__type(value, __u64);
} egress SEC(".maps");

static __always_inline void add(__u32 k, __u64 v)
{
	__u64 *c = bpf_map_lookup_elem(&egress, &k);
	if (c)
		__sync_fetch_and_add(c, v);
}

SEC("tc")
int count_egress(struct __sk_buff *skb)
{
	add(0, 1);                                // total packets
	add(9, skb->len);                         // total bytes (from __sk_buff metadata)

	__u32 proto = bpf_ntohs(skb->protocol);   // L3 protocol, pre-filled — no parsing
	if (proto == ETH_P_IP)        add(1, 1);
	else if (proto == ETH_P_IPV6) add(2, 1);
	else                          add(3, 1);

	return TC_ACT_OK;                         // never drop — observe only
}

char LICENSE[] SEC("license") = "GPL";
