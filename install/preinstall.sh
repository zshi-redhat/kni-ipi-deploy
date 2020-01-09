#!/bin/bash

# Run this script second-to-last, as your non-root user!
#
# 1. baremetal_prep.sh (from openshift-kni/baremetal-deploy)
# 2. dns/start.sh (run on DNS/DHCP server)
# 3. dhcp/start.sh (run on DNS/DHCP server)
# 4. iptables/gen_iptables.sh
# 5. install/preinstall.sh (this script)
# 6. install/install.sh 

# Latest available STABLE release for baremetal at time of check-in
VERSION="4.3.0-0.nightly-2020-01-08-181129"
RELEASE_IMAGE="registry.svc.ci.openshift.org/ocp/release:4.3.0-0.nightly-2020-01-08-181129"
CMD=openshift-baremetal-install
PULL_SECRET=~/pull-secret.json
EXTRACT_DIR=$(pwd)
# Get the oc binary
curl -s https://openshift-release-artifacts.svc.ci.openshift.org/$VERSION/openshift-client-linux-$VERSION.tar.gz | tar zxvf - oc
sudo cp ./oc /usr/local/bin/oc
# Extract the baremetal installer
oc adm release extract --registry-config "${PULL_SECRET}" --command=$CMD --to "${EXTRACT_DIR}" ${RELEASE_IMAGE}

COMMIT_ID=$(./openshift-baremetal-install version | grep '^built from commit' | awk '{print $4}')

export RHCOS_URI=$(curl -s -S https://raw.githubusercontent.com/openshift/installer/$COMMIT_ID/data/data/rhcos.json | jq .images.openstack.path | sed 's/"//g')
export RHCOS_PATH=$(curl -s -S https://raw.githubusercontent.com/openshift/installer/$COMMIT_ID/data/data/rhcos.json | jq .baseURI | sed 's/"//g')

# Place the URL printed by the following command into your metal3-config.yaml
# as the "rhcos_image_url" value if necessary
echo "RHCOS IMAGE: $RHCOS_PATH$RHCOS_URI"
