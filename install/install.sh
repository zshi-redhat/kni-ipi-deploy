#!/bin/bash

# Run this script last, as your non-root user!
#
# On DHS/DHCP server:
#
# 1. dns/start.sh 
# 2. dhcp/start.sh
# 3. iptables/gen_iptables.sh
#
# On provisioning host:
#
# 1. baremetal_prep.sh (from openshift-kni/baremetal-deploy)
# 2. install/preinstall.sh 
# 3. install/install.sh (this script)

# Create new clusterconfigs dir and put install-config.yaml in it
rm -rf ~/clusterconfigs
mkdir ~/clusterconfigs
# NOTE: We assume you copy cluster/install-config.yaml to your home dir and 
#       inject pull secret and ssh key!  It will also be placed there by
#       baremetal-prep.sh script from openshift-kni/baremetal-deploy if you
#       ask that script to generate it
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
# NOTE: metal3-config.yaml should be in your non-root user's home directory,
#       as the baremetal-prep.sh script from openshift-kni/baremetal-deploy
#       will place it there
cp ~/metal3-config.yaml ~/clusterconfigs/openshift/99_metal3-config.yaml

# Run the install command
./openshift-baremetal-install --dir ~/clusterconfigs --log-level debug create cluster
