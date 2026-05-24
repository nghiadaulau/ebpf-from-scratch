# 11 — XDP: earliest-point packet processing, write a firewall

**XDP** (eXpress Data Path) attaches an eBPF program to the network driver. It runs
on every incoming packet *before the kernel allocates an `sk_buff`* — the earliest
point software can touch a packet. That's why XDP is the basis of high-speed DDoS
drop and load balancing (Cloudflare, Facebook/Katran).

A program returns a **verdict**:

| Verdict          | Meaning                                            |
|------------------|----------------------------------------------------|
| `XDP_PASS`       | let it continue up the stack (allocate sk_buff...) |
| `XDP_DROP`       | drop right in the driver — cheapest possible       |
| `XDP_TX`         | bounce it back out the same NIC                     |
| `XDP_REDIRECT`   | send to another NIC / CPU / AF_XDP socket          |

## Files

- `xdp_fw.bpf.c` — a tiny firewall: drop ICMP, pass everything else, count drops in a map.
- `commands.sh` — build, attach to an interface, test, read counter, auto-detach.

## Reading packets safely

XDP gives you `ctx->data` / `ctx->data_end`. **Every read must be bounds-checked**
against `data_end` before dereferencing — the verifier rejects the load otherwise
("invalid access to packet"). See article 02 for why.

## Run

```bash
./commands.sh ens5        # build + attach to ens5 + test + auto-detach on exit
```

### Why drop ICMP (and nothing else)?

SSH is TCP. Dropping ICMP on a remote box you're SSH'd into does **not** cut your
session. Rule of thumb when playing with XDP on a remote host: never drop the
traffic carrying your shell. Default everything to `XDP_PASS`.

### Expected result

Before attach: `ping` → 0% loss. After attach: `ping` → **100% loss** (the
echo-*reply* is dropped on ingress), while SSH stays alive. The `icmp_drops` map
counts exactly the number of dropped packets.

## Attach modes

- **native** (`xdpdrv`) — in the driver, fastest, needs driver support.
- **offload** (`xdpoffload`) — on a SmartNIC, kernel never touches the packet.
- **generic** (`xdpgeneric`) — kernel emulation, works on any driver, safe for testing.

## Cleanup (mandatory)

```bash
sudo bpftool net detach xdpgeneric dev ens5
sudo rm -rf /sys/fs/bpf/xdpfw
```

A still-attached XDP program keeps filtering packets. `commands.sh` puts the detach
in a `trap ... EXIT` so it always runs.
