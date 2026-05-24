// Tetragon-style enforcement: observe with a tracepoint, then ACT by killing the
// process with bpf_send_signal() — the exact mechanism Tetragon uses for SIGKILL.
// Narrow + safe: only kills a process that exec's exactly "/tmp/forbidden-bin".
#include "vmlinux.h"
#include <bpf/bpf_helpers.h>

char LICENSE[] SEC("license") = "GPL";

SEC("tracepoint/sched/sched_process_exec")
int kill_forbidden(struct trace_event_raw_sched_process_exec *ctx)
{
	char fn[24] = {};
	unsigned off = ctx->__data_loc_filename & 0xFFFF;
	bpf_probe_read_kernel_str(fn, sizeof(fn), (void *)ctx + off);

	const char want[] = "/tmp/forbidden-bin";
	for (int i = 0; i < sizeof(want) - 1; i++)
		if (fn[i] != want[i])
			return 0;                 // not the target -> let it run

	bpf_send_signal(9);                       // SIGKILL the offending process
	return 0;
}
