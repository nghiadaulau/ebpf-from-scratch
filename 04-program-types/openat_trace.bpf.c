// A tracepoint program: fires on every openat() syscall.
// Its "context" comes from helpers (current comm/pid), printed to trace_pipe.
#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>

SEC("tracepoint/syscalls/sys_enter_openat")
int on_openat(void *ctx)
{
	char comm[16];
	bpf_get_current_comm(comm, sizeof(comm));
	__u32 pid = bpf_get_current_pid_tgid() >> 32;
	bpf_printk("openat by %s (pid %d)", comm, pid);
	return 0;
}

char _license[] SEC("license") = "GPL";
