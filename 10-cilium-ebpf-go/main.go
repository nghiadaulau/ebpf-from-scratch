// execsnoop in Go using cilium/ebpf: load the eBPF object, attach the tracepoint,
// read events from the ring buffer. bpf2go (go:generate) compiles exec.bpf.c and
// produces the Go bindings (execObjects / loadExecObjects / HandleExec / Events).
package main

import (
	"bytes"
	"encoding/binary"
	"errors"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/cilium/ebpf/link"
	"github.com/cilium/ebpf/ringbuf"
	"github.com/cilium/ebpf/rlimit"
)

//go:generate go run github.com/cilium/ebpf/cmd/bpf2go -cc clang exec exec.bpf.c -- -I.

type event struct {
	Pid      uint32
	Ppid     uint32
	Comm     [16]byte
	Filename [64]byte
}

func cstr(b []byte) string {
	if i := bytes.IndexByte(b, 0); i >= 0 {
		b = b[:i]
	}
	return string(b)
}

func main() {
	if err := rlimit.RemoveMemlock(); err != nil {
		log.Fatal(err)
	}
	var objs execObjects
	if err := loadExecObjects(&objs, nil); err != nil {
		log.Fatal("load:", err)
	}
	defer objs.Close()

	tp, err := link.Tracepoint("sched", "sched_process_exec", objs.HandleExec, nil)
	if err != nil {
		log.Fatal("attach:", err)
	}
	defer tp.Close()

	rd, err := ringbuf.NewReader(objs.Events)
	if err != nil {
		log.Fatal("ringbuf:", err)
	}
	defer rd.Close()

	go func() {
		sig := make(chan os.Signal, 1)
		signal.Notify(sig, os.Interrupt, syscall.SIGTERM)
		<-sig
		rd.Close()
	}()

	fmt.Printf("%-16s %-8s %-8s %s\n", "COMM", "PID", "PPID", "FILENAME")
	var e event
	for {
		rec, err := rd.Read()
		if err != nil {
			if errors.Is(err, ringbuf.ErrClosed) {
				return
			}
			continue
		}
		if err := binary.Read(bytes.NewReader(rec.RawSample), binary.LittleEndian, &e); err != nil {
			continue
		}
		fmt.Printf("%-16s %-8d %-8d %s\n", cstr(e.Comm[:]), e.Pid, e.Ppid, cstr(e.Filename[:]))
	}
}
