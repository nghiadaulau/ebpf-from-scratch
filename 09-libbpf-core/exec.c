#include <stdio.h>
#include <signal.h>
#include <stdbool.h>
#include <bpf/libbpf.h>
#include "exec.h"
#include "exec.skel.h"

static volatile bool stop;
static void on_sig(int sig) { stop = true; }

static int on_event(void *ctx, void *data, size_t sz)
{
	struct event *e = data;
	printf("%-16s pid=%-7u ppid=%-7u %s\n", e->comm, e->pid, e->ppid, e->filename);
	return 0;
}

int main(void)
{
	setvbuf(stdout, NULL, _IOLBF, 0);
	struct exec_bpf *skel = exec_bpf__open_and_load();
	if (!skel) { fprintf(stderr, "open_and_load failed\n"); return 1; }
	if (exec_bpf__attach(skel)) { fprintf(stderr, "attach failed\n"); return 1; }

	struct ring_buffer *rb =
		ring_buffer__new(bpf_map__fd(skel->maps.events), on_event, NULL, NULL);

	signal(SIGINT, on_sig);
	printf("%-16s %-11s %-12s %s\n", "COMM", "PID", "PPID", "FILENAME");
	while (!stop)
		ring_buffer__poll(rb, 100 /*ms*/);

	ring_buffer__free(rb);
	exec_bpf__destroy(skel);
	return 0;
}
