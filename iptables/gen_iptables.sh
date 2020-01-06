#!/bin/bash

###------------------------------------------------###
### Need interface input from user via environment ###
###------------------------------------------------###

# shellcheck disable=SC1091
source "../settings.sh"

ins_del_rule()
{
    operation=$1
    table=$2
    rule=$3
   
    if [ "$operation" == "INSERT" ]; then
        if ! sudo iptables -t "$table" -C $rule > /dev/null 2>&1; then
            sudo iptables -t "$table" -I $rule
        fi
    elif [ "$operation" == "DELETE" ]; then
        sudo iptables -t "$table" -D $rule
    else
        echo "${FUNCNAME[0]}: Invalid operation: $operation"
        exit 1
    fi
}

# allow DNS/DHCP traffic to dnsmasq and coredns
ins_del_rule "INSERT" "filter" "INPUT -i $BM_BRIDGE -p udp -m udp --dport 67 -j ACCEPT"
ins_del_rule "INSERT" "filter" "INPUT -i $BM_BRIDGE -p udp -m udp --dport 53 -j ACCEPT"
ins_del_rule "INSERT" "filter" "INPUT -i $BM_BRIDGE -p tcp -m tcp --dport 67 -j ACCEPT"
ins_del_rule "INSERT" "filter" "INPUT -i $BM_BRIDGE -p tcp -m tcp --dport 53 -j ACCEPT"
ins_del_rule "INSERT" "filter" "INPUT -i $BM_BRIDGE -p tcp -m tcp --dport 6443 -j ACCEPT"

# enable routing from cluster network to external
ins_del_rule "INSERT" "nat" "POSTROUTING -o $EXT_INTF -j MASQUERADE"
ins_del_rule "INSERT" "filter" "FORWARD -i $BM_BRIDGE -o $EXT_INTF -j ACCEPT"
ins_del_rule "INSERT" "filter" "FORWARD -o $BM_BRIDGE -i $EXT_INTF -m state --state RELATED,ESTABLISHED -j ACCEPT"

# remove certain problematic REJECT rules
REJECT_RULE=$(iptables -S | grep "INPUT -j REJECT --reject-with icmp-host-prohibited")

if [[ -n "$REJECT_RULE" ]]; then
    sudo iptables -D INPUT -j REJECT --reject-with icmp-host-prohibited
fi

REJECT_RULE2=$(iptables -S | grep "FORWARD -j REJECT --reject-with icmp-host-prohibited")

if [[ -n "$REJECT_RULE2" ]]; then
    sudo iptables -D FORWARD -j REJECT --reject-with icmp-host-prohibited
fi