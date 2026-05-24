// XDP program that reads the first packet byte WITHOUT a bounds check.
// The verifier rejects this: it cannot prove the read stays within the packet.
#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>

SEC("xdp")
int xdp_bad(struct xdp_md *ctx)
{
	void *data = (void *)(long)ctx->data;
	char first = *(char *)data;            // no `data_end` check -> rejected
	return first ? XDP_DROP : XDP_PASS;
}

char _license[] SEC("license") = "GPL";
