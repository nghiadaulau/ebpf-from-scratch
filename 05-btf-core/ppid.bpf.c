// CO-RE: read a nested kernel struct field (task->real_parent->tgid = ppid)
// without hardcoding offsets. Compiled once; libbpf relocates field offsets
// at load time using the running kernel's BTF.
#include "vmlinux.h"
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_core_read.h>

SEC("tracepoint/sched/sched_process_exec")
int on_exec(void *ctx)
{
	struct task_struct *task = (struct task_struct *)bpf_get_current_task();
	__u32 ppid = BPF_CORE_READ(task, real_parent, tgid);   // CO-RE relocation
	char comm[16];
	bpf_get_current_comm(comm, sizeof(comm));
	bpf_printk("exec %s ppid=%d", comm, ppid);
	return 0;
}

char _license[] SEC("license") = "GPL";
