# 13 — Write your own tc program: __sk_buff and the tcx chain

Article 12 *read* Cilium's tc datapath. Here we *write* a `sched_cls` program — an
egress packet counter classified by L3 protocol — to learn two things from the
inside: **`__sk_buff`** and **tcx** chaining.

## `__sk_buff` vs XDP's raw frame

XDP hands you `xdp_md` — basically two pointers to a raw frame; you parse everything.
tc hands you **`__sk_buff`**, a view onto the `sk_buff` the kernel already built, with
metadata filled in:

- `skb->protocol` — L3 protocol (`ETH_P_IP`…), already set (`__be16`, use `bpf_ntohs`)
- `skb->len` — packet length
- `skb->mark`, `skb->ifindex`, `skb->priority` — fwmark, interface, etc.

So `count.bpf.c` classifies by protocol **without parsing a single byte** — the price
of running *after* `sk_buff` is built, the payoff is ready-made metadata.

## Run

```bash
./commands.sh lo      # build + tcx-attach on lo + traffic + read counts + auto-detach
```

Expected (loopback): IPv4 and IPv6 counts that match the ping/ping6 you generate,
`other` = 0, plus a byte total.

## The tcx-chain lesson

Attaching this **on `ens5`** (the physical NIC) instead shows a **total of 0** even
with traffic flowing. Not a bug. From the node's own `/usr/include/linux/bpf.h`:

```c
enum tcx_action_base {
	TCX_NEXT     = -1,   // run the NEXT program in the chain
	TCX_PASS     = 0,    // == TC_ACT_OK: pass, STOP the chain
	TCX_DROP     = 2,    // == TC_ACT_SHOT
	TCX_REDIRECT = 7,    // == TC_ACT_REDIRECT
};
```

Cilium's `cil_to_netdev` is first in the egress chain and returns a *terminating*
verdict (PASS/REDIRECT), so the chain stops before reaching our program (attached
after it). To run on `ens5` you must attach **before** Cilium with `BPF_F_BEFORE`
(a tcx feature). On a hook that already has an owner, chain order is everything.

## tcx

`tcx` is the link-based tc attach added in **Linux 6.6** (Daniel Borkmann). Multiple
programs chain on one hook with safe ownership, auto-detach on close, and explicit
ordering via `BPF_F_BEFORE` / `BPF_F_AFTER`.

## Cleanup (mandatory)

```bash
sudo bpftool net detach tcx_egress dev lo
sudo rm -rf /sys/fs/bpf/tccount
```
