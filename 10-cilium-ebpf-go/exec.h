#ifndef __EXEC_H
#define __EXEC_H
struct event {
	unsigned int pid;
	unsigned int ppid;
	char comm[16];
	char filename[64];
};
#endif
