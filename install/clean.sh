#!/bin/bash

for i in $(sudo virsh list | tail -n +3 | grep bootstrap | awk {'print $2'}); 
do 
	sudo virsh destroy $i;
	sudo virsh undefine $i;
	sudo virsh vol-delete $i --pool default; 
	sudo virsh vol-delete $i.ign --pool default;
done

if [[ -f "$HOME/install-config.yaml" ]]; then
	# Make sure all nodes are powered off
	for i in $(yq -c '.platform.baremetal.hosts[].bmc' ~/install-config.yaml); do 
		ipmitool -I lanplus -U "$(echo "$i" | jq -r '.username')" -P "$(echo "$i" | jq -r '.password')" -H "$(echo "$i" | jq -r '.address' | cut -d '/' -f 3)" power off
	done
fi