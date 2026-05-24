#include "vmlinux.h"
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_core_read.h>
#include <bpf/bpf_tracing.h>

char LICENSE[] SEC("license") = "GPL";

// Deny opening any file named exactly "lsm-secret". Safe: affects only that name.
SEC("lsm/file_open")
int BPF_PROG(deny_open, struct file *file, int ret)
{
	if (ret != 0)            // a previous LSM already decided -> respect it
		return ret;
	char name[16] = {};
	const unsigned char *p = BPF_CORE_READ(file, f_path.dentry, d_name.name);
	bpf_probe_read_kernel_str(name, sizeof(name), p);
	// compare to "lsm-secret"
	const char want[] = "lsm-secret";
	for (int i = 0; i < sizeof(want) - 1; i++)
		if (name[i] != want[i])
			return 0;        // not our target -> allow
	return -1;                       // -EPERM: deny
}
