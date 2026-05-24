#!/usr/bin/env bash
# How Hubble turns eBPF datapath events into cluster-wide labeled flows.
# Read-only: observes events already flowing; attaches nothing.
CID=$(sudo crictl ps --name cilium-agent -q | head -1)

# [2] The perf ring buffer the datapath writes events into (one slot per CPU)
sudo bpftool map show | grep cilium_events

# [2] Raw datapath events (cilium-agent reads cilium_events) — identities are NUMERIC
sudo timeout 7 crictl exec "$CID" cilium monitor | head -25

# [3] Hubble enriches numeric identity -> pod/service name + verdict
sudo crictl exec "$CID" hubble observe --last 12 -o compact

# [3] The enrichment source: identity number -> k8s labels
sudo crictl exec "$CID" cilium identity get 18203
