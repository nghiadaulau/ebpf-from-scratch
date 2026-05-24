#!/usr/bin/env bash
# Dissect a LIVE Cilium tc datapath on a node. Read-only — attaches nothing.

# How many tc/sched_cls programs are loaded (most are Cilium's)
sudo bpftool prog show | grep -c sched_cls

# Where they attach: physical NIC, host devices, and each pod's veth (lxc*)
sudo bpftool net show

# The datapath split into tail-called programs (note the tail_* names)
sudo bpftool prog show | grep sched_cls

# Cilium datapath maps (LB table, conntrack, endpoints, policy, tail-call array)
sudo bpftool map show | grep -i cilium

# --- human-readable views from the cilium agent (run inside the cilium-agent container) ---
CID=$(sudo crictl ps --name cilium-agent -q | head -1)

# Service load balancing IS a map: VIP -> backends (kube-proxy-less)
sudo crictl exec "$CID" cilium bpf lb list          # reads cilium_lb4_services

# Connection tracking, with each flow's source security identity
sudo crictl exec "$CID" cilium bpf ct list global   # reads cilium_ct4_global

# Pod -> identity mapping that NetworkPolicy is enforced on (not IPs)
sudo crictl exec "$CID" cilium endpoint list        # reads cilium_lxc
