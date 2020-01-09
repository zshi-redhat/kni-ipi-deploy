#!/bin/bash

# Run this script last, as your non-root user!
#
# 1. baremetal_prep.sh (from openshift-kni/baremetal-deploy)
# 2. dns/start.sh (run on DNS/DHCP server)
# 3. dhcp/start.sh (run on DNS/DHCP server)
# 4. iptables/gen_iptables.sh
# 5. install/preinstall.sh
# 6. install/install.sh (this script)

# Create new clusterconfigs dir and put install-config.yaml in it
rm -rf ~/clusterconfigs
mkdir ~/clusterconfigs
# NOTE: We assume you copy cluster/install-config.yaml to your home dir and inject pull secret and ssh key!
cp ~/install-config.yaml ~/clusterconfigs

# Make sure all nodes are powered off
for i in $(yq -c '.platform.baremetal.hosts[].bmc' ~/install-config.yaml); do 
    ipmitool -I lanplus -U "$(echo "$i" | jq -r '.username')" -P "$(echo "$i" | jq -r '.password')" -H "$(echo "$i" | jq -r '.address' | cut -d '/' -f 3)" power off
done

# Create manifests
./openshift-baremetal-install --dir ~/clusterconfigs create manifests

# Add NM overrides to openshift manifests
cp ../hacks/* ~/clusterconfigs/openshift/.

# Add metal3-config.yaml to openshift manifests
cp ../metal3-config.yaml ~/clusterconfigs/openshift/99_metal3-config.yaml

# Run the install command
./openshift-baremetal-install --dir ~/clusterconfigs --log-level debug create cluster
