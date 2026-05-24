# 07 — bpftrace: maps, count, histogram

Article (Vietnamese): https://kkloudtarus.net/blog/bpftrace-maps-aggregation

In-kernel aggregation: count by key, build distribution histograms, return only the
summary. Run with `sudo bpftrace <file>.bt`.

- `openat_by_comm.bt`    — count openat() per process (`@map[key] = count()`).
- `vfs_read_latency.bt`  — vfs_read latency histogram (kprobe+kretprobe + nsecs).
