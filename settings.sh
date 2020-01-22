#!/bin/bash

# Leave as-is
export API_VIP="10.0.1.4"

# Leave as-is
export BM_BRIDGE="baremetal"

# Should be the IP you intend to use on the baremetal bridge on your DNS/DHCP server
export BM_GW_IP="10.0.1.2"

export CLUSTER_DOMAIN="ipi.testing"
export CLUSTER_NAME="goblin"

# Should be the IP you intend to use on the baremetal bridge on your DNS/DHCP server
export DNS_IP="10.0.1.2"

# Leave as-is
export DNS_VIP="10.0.1.3"

# Should be the external interface of the DNS/DHCP server
export EXT_INTF="eno1"

# Leave as-is
export INGRESS_VIP="10.0.1.5"

# Provisioning MACs
export MASTER_0_MAC="0c:c4:7a:db:a8:55"
export MASTER_1_MAC="0C:C4:7A:DB:A9:93"
export MASTER_2_MAC="0C:C4:7A:DB:A8:59"

# Baremetal MACs
export MASTER_0_BM_MAC="0c:c4:7a:19:6f:84"
export MASTER_1_BM_MAC="0c:c4:7a:19:6f:92"
export MASTER_2_BM_MAC="0c:c4:7a:19:70:cc"

export MASTER_COUNT="3"

# Leave as-is
export PROV_BRIDGE="provisioning"

export PROV_BM_MAC="0c:c4:7a:19:6f:86"

# Provisioning MACs
export WORKER_0_MAC="0C:C4:7A:DB:AC:03"
export WORKER_1_MAC="0c:c4:7a:db:a9:b3"
export WORKER_2_MAC="0c:c4:7a:db:a9:b1"

# Baremetal MACs
export WORKER_0_BM_MAC="0c:c4:7a:19:6f:7e"
export WORKER_1_BM_MAC="0c:c4:7a:8e:ed:ec"
export WORKER_2_BM_MAC="0c:c4:7a:8e:ed:f8"

export WORKER_COUNT="3"
