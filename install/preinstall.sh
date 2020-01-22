#!/bin/bash

# Run this script second-to-last, as your non-root user!
#
# 1. baremetal_prep.sh (from openshift-kni/baremetal-deploy)
# 2. dns/start.sh (run on DNS/DHCP server)
# 3. dhcp/start.sh (run on DNS/DHCP server)
# 4. iptables/gen_iptables.sh
# 5. install/preinstall.sh (this script)
# 6. install/install.sh 

# Latest stable 4.3 release as of check-in
VERSION="4.3.0-0.nightly-2020-01-16-031402"
RELEASE_IMAGE=$(curl -s https://openshift-release-artifacts.svc.ci.openshift.org/$VERSION/release.txt | grep 'Pull From: registry' | awk -F ' ' '{print $3}' | xargs)
CMD=openshift-baremetal-install
PULL_SECRET=~/pull-secret.json
EXTRACT_DIR=$(pwd)
# Get the oc binary
curl https://openshift-release-artifacts.svc.ci.openshift.org/$VERSION/openshift-client-linux-$VERSION.tar.gz | tar zxvf - oc
sudo cp ./oc /usr/local/bin/oc
# Extract the baremetal installer
oc adm release extract --registry-config "${PULL_SECRET}" --command=$CMD --to "${EXTRACT_DIR}" ${RELEASE_IMAGE}

COMMIT_ID=$(./openshift-baremetal-install version | grep '^built from commit' | awk '{print $4}')

export RHCOS_URI=$(curl -s -S https://raw.githubusercontent.com/openshift/installer/$COMMIT_ID/data/data/rhcos.json | jq .images.openstack.path | sed 's/"//g')
export RHCOS_PATH=$(curl -s -S https://raw.githubusercontent.com/openshift/installer/$COMMIT_ID/data/data/rhcos.json | jq .baseURI | sed 's/"//g')

# Place the URL printed by the following command into your metal3-config.yaml
# as the "rhcos_image_url" value if necessary
IMAGE_URL="$RHCOS_PATH$RHCOS_URI"
echo "RHCOS URI: $RHCOS_URI"
echo "RHCOS IMAGE: $IMAGE_URL"

# Set up the image cache to boost bootstrap performance
IMAGE_FILE=$(echo "$RHCOS_URI" | rev | cut -d '.' -f 2- | rev)
echo "IMAGE_FILE: $IMAGE_FILE"
IMAGE_DIR="$HOME/image_cache/images/$IMAGE_FILE"

mkdir -p "$IMAGE_DIR"

(
    COMP_IMAGE_FILE=$(echo "$IMAGE_FILE" | sed 's/openstack/compressed/')
    USER=$(whoami)

    cd "$IMAGE_DIR"

    if [[ ! -f "$COMP_IMAGE_FILE" ]]; then
        echo "Pre-caching $IMAGE_FILE for bootstrap..."
        curl -O -L "$IMAGE_URL"
        gzip -d "$IMAGE_FILE.gz"
        qemu-img convert -O qcow2 -c "$IMAGE_FILE" "$COMP_IMAGE_FILE"
        md5sum "$COMP_IMAGE_FILE" | cut -f 1 -d ' ' > "$COMP_IMAGE_FILE.md5sum"
    fi

    sudo podman rm -f image_cache >/dev/null
    sudo podman run --name image_cache -p 172.22.0.1:80:80/tcp -v /home/"$USER"/image_cache:/usr/share/nginx/html:ro -d nginx

) || exit 1

