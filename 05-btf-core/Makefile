# vmlinux.h is generated from the running kernel's BTF (not committed; see .gitignore).
all: ppid.bpf.o
vmlinux.h:
	sudo bpftool btf dump file /sys/kernel/btf/vmlinux format c > vmlinux.h
ppid.bpf.o: ppid.bpf.c vmlinux.h
	clang -O2 -g -target bpf -I. -c ppid.bpf.c -o ppid.bpf.o
clean:
	rm -f ppid.bpf.o vmlinux.h
