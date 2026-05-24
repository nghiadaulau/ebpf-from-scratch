ARCH := $(shell uname -m)
CFLAGS := -O2 -g -target bpf -I/usr/include/$(ARCH)-linux-gnu
all: openat_trace.bpf.o
%.bpf.o: %.bpf.c
	clang $(CFLAGS) -c $< -o $@
clean:
	rm -f *.bpf.o
