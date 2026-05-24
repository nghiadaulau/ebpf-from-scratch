ARCH := $(shell uname -m)
CFLAGS := -O2 -g -target bpf -I/usr/include/$(ARCH)-linux-gnu
all: count_exec.bpf.o
%.bpf.o: %.bpf.c
	clang $(CFLAGS) -c $< -o $@
clean:
	rm -f *.bpf.o
