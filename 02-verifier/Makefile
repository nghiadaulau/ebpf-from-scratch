# Compile the XDP programs to eBPF bytecode.
ARCH := $(shell uname -m)
CFLAGS := -O2 -g -target bpf -I/usr/include/$(ARCH)-linux-gnu

all: xdp_bad.bpf.o xdp_good.bpf.o
%.bpf.o: %.bpf.c
	clang $(CFLAGS) -c $< -o $@
clean:
	rm -f *.bpf.o
