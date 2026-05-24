// seccomp-bpf demo: install a CLASSIC BPF (cBPF) filter that denies mkdir/mkdirat
// with EPERM, allows everything else. cBPF — the same BPF that tcpdump uses — not eBPF.
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/prctl.h>
#include <linux/seccomp.h>
#include <linux/filter.h>
#include <linux/audit.h>
#include <stddef.h>
#include <sys/syscall.h>

int main(void) {
	// classic BPF program over struct seccomp_data
	struct sock_filter filter[] = {
		// A = seccomp_data.arch ; ensure x86_64 (defensive)
		BPF_STMT(BPF_LD | BPF_W | BPF_ABS, offsetof(struct seccomp_data, arch)),
		BPF_JUMP(BPF_JMP | BPF_JEQ | BPF_K, AUDIT_ARCH_X86_64, 1, 0),
		BPF_STMT(BPF_RET | BPF_K, SECCOMP_RET_ALLOW),     // other arch: allow
		// A = seccomp_data.nr (syscall number)
		BPF_STMT(BPF_LD | BPF_W | BPF_ABS, offsetof(struct seccomp_data, nr)),
		BPF_JUMP(BPF_JMP | BPF_JEQ | BPF_K, __NR_mkdir,   2, 0),
		BPF_JUMP(BPF_JMP | BPF_JEQ | BPF_K, __NR_mkdirat, 1, 0),
		BPF_STMT(BPF_RET | BPF_K, SECCOMP_RET_ALLOW),     // not mkdir*: allow
		BPF_STMT(BPF_RET | BPF_K, SECCOMP_RET_ERRNO | (EPERM & SECCOMP_RET_DATA)),
	};
	struct sock_fprog prog = { .len = sizeof(filter)/sizeof(filter[0]), .filter = filter };

	printf("filter has %zu cBPF instructions\n", sizeof(filter)/sizeof(filter[0]));

	// mkdir works BEFORE the filter
	printf("before filter: mkdir /tmp/sc-a -> %s\n",
	       mkdir("/tmp/sc-a", 0755) == 0 ? "OK" : strerror(errno));

	prctl(PR_SET_NO_NEW_PRIVS, 1, 0, 0, 0);               // required for unprivileged
	if (prctl(PR_SET_SECCOMP, SECCOMP_MODE_FILTER, &prog)) {
		perror("prctl SET_SECCOMP"); return 1;
	}
	printf("seccomp filter installed (mode 2)\n");

	// mkdir is now denied; write/printf still works (proves it's selective)
	printf("after filter:  mkdir /tmp/sc-b -> %s\n",
	       mkdir("/tmp/sc-b", 0755) == 0 ? "OK" : strerror(errno));
	printf("after filter:  this printf still works (write syscall allowed)\n");
	return 0;
}
