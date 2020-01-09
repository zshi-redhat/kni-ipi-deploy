#!/bin/bash

for i in $(sudo virsh list | grep -v Name | grep -v "\-\-\-" | awk {'print $2'}); 
do 
	sudo virsh destroy $i;
	sudo virsh undefine $i;
	sudo virsh vol-delete $i --pool default; 
	sudo virsh vol-delete $i.ign --pool default;
done
