#!/bin/bash

# Leave as-is
export API_VIP="10.0.1.4"

# Leave as-is
export BM_BRIDGE="baremetal"

# Should be the IP you intend to use on the baremetal bridge on your DNS/DHCP server
export BM_GW_IP="10.0.1.2"

export CLUSTER_DOMAIN="ovn.testing"
export CLUSTER_NAME="sriov"

# Should be the IP you intend to use on the baremetal bridge on your DNS/DHCP server
export DNS_IP="10.0.1.2"

# Leave as-is
export DNS_VIP="10.0.1.3"

# Should be the external interface of the DNS/DHCP server
export EXT_INTF="eno1"

# Leave as-is
export INGRESS_VIP="10.0.1.5"

# Provisioning MACs
export MASTER_0_MAC="a4:bf:01:51:30:4c"
export MASTER_1_MAC="a4:bf:01:51:42:19"
export MASTER_2_MAC="a4:bf:01:51:30:53"

# Baremetal MACs
export MASTER_0_BM_MAC="3c:fd:fe:b5:18:8c"
export MASTER_1_BM_MAC="3c:fd:fe:b5:75:fc"
export MASTER_2_BM_MAC="3c:fd:fe:b5:80:ac"

export MASTER_COUNT="3"

# Leave as-is
export PROV_BRIDGE="provisioning"

export PROV_BM_MAC="3c:fd:fe:a0:d7:e1"

# Provisioning MACs
export WORKER_0_MAC="a4:bf:01:51:7e:40"
export WORKER_1_MAC="a4:bf:01:51:47:59"

# Baremetal MACs
export WORKER_0_BM_MAC="98:03:9b:97:38:de"
export WORKER_1_BM_MAC="98:03:9b:97:21:e6"

export WORKER_COUNT="2"
