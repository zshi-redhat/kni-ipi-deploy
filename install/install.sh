#!/bin/bash

# Run this script last!

VERSION=$(curl -s https://mirror.openshift.com/pub/openshift-v4/clients/ocp-dev-preview/latest/release.txt | grep 'Name:' | awk -F: '{print $2}' | xargs)
RELEASE_IMAGE=$(curl -s https://mirror.openshift.com/pub/openshift-v4/clients/ocp-dev-preview/latest/release.txt | grep 'Pull From: quay.io' | awk -F ' ' '{print $3}' | xargs)

export CMD=openshift-baremetal-install
export PULL_SECRET=~/pull-secret.json
export EXTRACT_DIR=$(pwd)
# Get the oc binary
curl -s https://mirror.openshift.com/pub/openshift-v4/clients/ocp-dev-preview/$VERSION/openshift-client-linux-$VERSION.tar.gz | tar zxvf - oc
sudo cp ./oc /usr/local/bin/oc
# Extract the baremetal installer
oc adm release extract --registry-config "${PULL_SECRET}" --command=$CMD --to "${EXTRACT_DIR}" ${RELEASE_IMAGE}

rm -rf ~/clusterconfigs
mkdir ~/clusterconfigs
cp ~/install-config.yaml ~/clusterconfigs

# TODO: Loop through install-config.yaml and make sure each node is powered-down
# ipmitool -I lanplus -U <user> -P <password> -H <management-server-ip> power off

COMMIT_ID=$(./openshift-baremetal-install version | grep '^built from commit' | awk '{print $4}')
RHCOS_URI=$(curl -s -S https://raw.githubusercontent.com/openshift/installer/$COMMIT_ID/data/data/rhcos.json | jq .images.openstack.path | sed 's/"//g')
RHCOS_PATH=$(curl -s -S https://raw.githubusercontent.com/openshift/installer/$COMMIT_ID/data/data/rhcos.json | jq .baseURI | sed 's/"//g')
envsubst < ~/metal3-config.yaml > metal3-config.yaml

./openshift-baremetal-install --dir ~/clusterconfigs create manifests

cp ~/metal3-config.yaml ~/clusterconfigs/openshift/99_metal3-config.yaml