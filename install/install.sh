#!/bin/bash

# Run this script last, as your non-root user!
#
# 1. baremetal_prep.sh (from openshift-kni/baremetal-deploy)
# 2. dns/start.sh
# 3. dhcp/start.sh
# 4. iptables/gen_iptables.sh
# 5. install/install.sh (this script)

# Determine latest release of OCP
VERSION=$(curl -s https://mirror.openshift.com/pub/openshift-v4/clients/ocp-dev-preview/latest/release.txt | grep 'Name:' | awk -F: '{print $2}' | xargs)
RELEASE_IMAGE=$(curl -s https://mirror.openshift.com/pub/openshift-v4/clients/ocp-dev-preview/latest/release.txt | grep 'Pull From: quay.io' | awk -F ' ' '{print $3}' | xargs)
CMD=openshift-baremetal-install
PULL_SECRET=~/pull-secret.json
EXTRACT_DIR=$(pwd)
# Get the oc binary
curl -s https://mirror.openshift.com/pub/openshift-v4/clients/ocp-dev-preview/$VERSION/openshift-client-linux-$VERSION.tar.gz | tar zxvf - oc
sudo cp ./oc /usr/local/bin/oc
# Extract the baremetal installer
oc adm release extract --registry-config "${PULL_SECRET}" --command=$CMD --to "${EXTRACT_DIR}" ${RELEASE_IMAGE}

# Create new clusterconfigs dir and put install-config.yaml in it
rm -rf ~/clusterconfigs
mkdir ~/clusterconfigs
cp ~/install-config.yaml ~/clusterconfigs

# Make sure all nodes are powered off
for i in $(yq -c '.platform.baremetal.hosts[].bmc' ~/install-config.yaml); do 
    ipmitool -I lanplus -U "$(echo "$i" | jq -r '.username')" -P "$(echo "$i" | jq -r '.password')" -H "$(echo "$i" | jq -r '.address' | cut -d '/' -f 3)" power off
done

# Create manifests
./openshift-baremetal-install --dir ~/clusterconfigs create manifests

# Add metal3-config.yaml to openshift manifests
cp ~/metal3-config.yaml ~/clusterconfigs/openshift/99_metal3-config.yaml

# Run the install command
./openshift-baremetal-install --dir ~/clusterconfigs --log-level debug create cluster