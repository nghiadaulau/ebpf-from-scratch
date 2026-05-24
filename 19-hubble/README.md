# 19 — Hubble internals: from eBPF events to cluster-wide flows

Hubble shows every connection in the cluster by pod/service name and policy verdict —
with no sidecars. It's the top of a three-layer chain that **reuses the existing eBPF
datapath**:

```
[1] eBPF datapath (74 sched_cls progs, article 12) processes every packet
        | bpf_perf_event_output()   -- emit trace/drop/policy events
        v
[2] cilium_events   (perf_event_array BPF map, one slot per CPU)
        | cilium-agent opens a perf reader   (cilium monitor shows this: NUMERIC identities)
        v
[3] Hubble enriches numeric identity -> pod/service name + verdict
        v
    readable flow: "host -> kube-system/coredns:8080 FORWARDED"
```

## Run (read-only)

```bash
./commands.sh
```

## Layer 2 — raw (`cilium monitor`)

```text
-> endpoint 1797 identity host->35393 state new ifindex lxca0f2... 10.200.0.64:36830 -> 10.200.0.180:9808 tcp SYN
```

Direction (`-> endpoint`/`-> stack`/`-> network`), source->dest **security identity
(numeric)**, state (from conntrack, article 12), ifindex (pod veth), and the packet.

## Layer 3 — enriched (`hubble observe`)

```text
10.200.0.64:54764 (host) -> kube-system/coredns-87bb947d6-v29lc:8080 (ID:18203) to-endpoint FORWARDED
```

`identity 18203` becomes `kube-system/coredns-...` because Hubble looks it up:

```text
$ cilium identity get 18203
18203   k8s:k8s-app=kube-dns
        k8s:io.kubernetes.pod.namespace=kube-system
```

All the data is already in the eBPF event; Hubble just translates numbers to names.

## Why it's powerful

The datapath already sees every packet of every pod (article 12). Adding one
`bpf_perf_event_output` gives a full, identity-labeled flow stream — no sidecars, no app
changes. One kernel attach point, whole-cluster visibility.
