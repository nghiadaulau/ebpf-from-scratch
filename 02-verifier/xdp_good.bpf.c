// Same idea, but bounds-checked: the verifier can now prove the read is safe.
#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>

SEC("xdp")
int xdp_good(struct xdp_md *ctx)
{
	void *data     = (void *)(long)ctx->data;
	void *data_end = (void *)(long)ctx->data_end;
	if (data + 1 > data_end)               // bounds check BEFORE the read
		return XDP_PASS;
	char first = *(char *)data;
	return first ? XDP_DROP : XDP_PASS;
}

char _license[] SEC("license") = "GPL";
