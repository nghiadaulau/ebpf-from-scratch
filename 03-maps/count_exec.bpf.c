// Count process exec events into a BPF array map.
// The program (kernel side) increments the counter; userspace reads it via bpftool.
#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>

struct {
	__uint(type, BPF_MAP_TYPE_ARRAY);
	__uint(max_entries, 1);
	__type(key, __u32);
	__type(value, __u64);
} exec_count SEC(".maps");

SEC("tracepoint/sched/sched_process_exec")
int count_exec(void *ctx)
{
	__u32 key = 0;
	__u64 *val = bpf_map_lookup_elem(&exec_count, &key);
	if (val)
		__sync_fetch_and_add(val, 1);
	return 0;
}

char _license[] SEC("license") = "GPL";
