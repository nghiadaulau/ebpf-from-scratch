# Build the execsnoop libbpf+CO-RE tool. Needs clang, libbpf-dev, bpftool.
all: execsnoop
vmlinux.h:
	sudo bpftool btf dump file /sys/kernel/btf/vmlinux format c > vmlinux.h
exec.bpf.o: exec.bpf.c exec.h vmlinux.h
	clang -O2 -g -target bpf -I. -c exec.bpf.c -o exec.bpf.o
exec.skel.h: exec.bpf.o
	bpftool gen skeleton exec.bpf.o > exec.skel.h
execsnoop: exec.c exec.skel.h exec.h
	clang exec.c -o execsnoop -lbpf -lelf -lz
clean:
	rm -f exec.bpf.o exec.skel.h execsnoop vmlinux.h
