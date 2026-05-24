# 20 — Case study: one packet through Cilium's eBPF datapath

No new concepts — this ties the whole series together by following one packet when a pod
calls the cluster DNS Service (`10.32.0.10:53`), load-balanced to a real CoreDNS pod
(`10.200.0.44:53`). Every step points back to the article that explained that piece.

```
Pod -> Service 10.32.0.10:53
  1. veth lxc… -> cil_from_container  (tc/sched_cls, art 12-13; verified by verifier art 02, JIT art 01)
  2. tail call via cilium_call_policy (art 04): tail_handle_ipv4 -> tail_ipv4_ct_ingress -> cil_lxc_policy
  3. LB: look up cilium_lb4_services (BPF map, art 03/12) -> DNAT to 10.200.0.44:53 (kube-proxy-less)
  4. conntrack cilium_ct4_global + policy by IDENTITY 18203=CoreDNS (art 12/19)
  5. deliver: same-node veth redirect, or cil_to_netdev -> ens5 -> remote node
  6. emit event: bpf_perf_event_output -> cilium_events -> Hubble (art 19)
```

All of it is eBPF — one technology, many hooks, shared maps, chained by tail calls —
which is why Cilium replaces kube-proxy + iptables + a separate observability agent +
a policy agent with one in-kernel datapath. See the article for the annotated walk and
the real artifacts (lb4_services entry, ct entries, identity 18203, monitor flow).

Commands referenced here are read-only and live in articles 11–19.
