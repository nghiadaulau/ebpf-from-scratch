# 12 — tc/sched_cls and dissecting a live Cilium datapath

After XDP comes **tc**. eBPF plugs into it via `BPF_PROG_TYPE_SCHED_CLS` (shown by
`bpftool` as `sched_cls`). Unlike XDP it runs *after* the `sk_buff` is allocated,
sees **both ingress and egress**, and works with `__sk_buff` (full metadata). That's
why Cilium puts almost its entire datapath here.

This article is **read-only**: it dissects the 74 `sched_cls` programs already
running on a real node — it attaches nothing.

## XDP vs tc

|              | XDP             | tc/sched_cls               |
|--------------|-----------------|----------------------------|
| Runs         | before sk_buff  | after sk_buff              |
| Sees         | ingress only    | ingress **and** egress     |
| Data         | raw frame       | `__sk_buff` (mark, ifindex, cgroup…) |
| Where        | physical NIC    | any iface, incl. pod veths |

Kernels ≥5.10 add **tcx**, a link-based attach for tc — what this cluster uses.

## What you'll see

- **74** of the node's 140 eBPF programs are `sched_cls` (almost all Cilium's).
- They attach at `ens5` (`cil_from_netdev`, right after the XDP layer), at the host
  devices, and at **each pod veth** (`cil_from_container`) — count scales with pods.
- The datapath is split into **tail-called** programs (`tail_handle_ipv4` →
  `tail_ipv4_ct_ingress` → `cil_lxc_policy`) via the `cilium_call_policy` prog_array,
  because a single program is capped at 1M instructions.
- Three pillars are all just **map lookups**:
  - **Service LB** = look up `cilium_lb4_services` + DNAT (kube-proxy-less). You can
    read the real table: kube-apiserver `10.32.0.1:443` → two `:6443` backends.
  - **Conntrack** = `cilium_ct4_global` (each flow carries a source security identity).
  - **NetworkPolicy** = policy map keyed by pod **identity** (from labels), not IP.

## Run

```bash
./commands.sh
```

All commands are observation only. See the article for the annotated output.
