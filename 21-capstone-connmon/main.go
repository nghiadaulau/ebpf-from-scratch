// connmon — a tiny live monitor of new outgoing TCP connections, built on eBPF.
// kprobe(tcp_connect) -> ring buffer -> this Go loader prints each connection live.
package main

import (
	"bytes"
	"encoding/binary"
	"errors"
	"fmt"
	"net"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/cilium/ebpf/link"
	"github.com/cilium/ebpf/ringbuf"
	"github.com/cilium/ebpf/rlimit"
)

//go:generate go run github.com/cilium/ebpf/cmd/bpf2go -cc clang connmon connmon.bpf.c -- -I. -D__TARGET_ARCH_x86

type event struct {
	Pid   uint32
	Saddr uint32
	Daddr uint32
	Dport uint16
	Af    uint16
	Comm  [16]byte
}

func ipv4(a uint32) string { // a holds a __be32 read little-endian -> low byte = first octet
	return net.IPv4(byte(a), byte(a>>8), byte(a>>16), byte(a>>24)).String()
}
func cstr(b []byte) string {
	if i := bytes.IndexByte(b, 0); i >= 0 {
		return string(b[:i])
	}
	return string(b)
}

func main() {
	if err := rlimit.RemoveMemlock(); err != nil {
		panic(err)
	}
	objs := connmonObjects{}
	if err := loadConnmonObjects(&objs, nil); err != nil {
		panic(err)
	}
	defer objs.Close()

	kp, err := link.Kprobe("tcp_connect", objs.TraceTcpConnect, nil)
	if err != nil {
		panic(err)
	}
	defer kp.Close()

	rd, err := ringbuf.NewReader(objs.Events)
	if err != nil {
		panic(err)
	}
	defer rd.Close()

	go func() { // stop on Ctrl+C
		c := make(chan os.Signal, 1)
		signal.Notify(c, os.Interrupt, syscall.SIGTERM)
		<-c
		rd.Close()
	}()

	fmt.Printf("%-12s %-16s %-7s %-15s -> %s\n", "TIME", "COMM", "PID", "SADDR", "DADDR:PORT")
	var e event
	for {
		rec, err := rd.Read()
		if errors.Is(err, ringbuf.ErrClosed) {
			return
		}
		if err != nil {
			continue
		}
		if err := binary.Read(bytes.NewReader(rec.RawSample), binary.LittleEndian, &e); err != nil {
			continue
		}
		fmt.Printf("%-12s %-16s %-7d %-15s -> %s:%d\n",
			time.Now().Format("15:04:05.000"), cstr(e.Comm[:]), e.Pid,
			ipv4(e.Saddr), ipv4(e.Daddr), e.Dport)
	}
}
