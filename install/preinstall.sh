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
VERSION="4.3.0-0.nightly-2020-01-27-075019"

if [[ -z "$VERSION" ]]; then
    echo "No version selected, trying \"latest\"..."
    VERSION=$(curl -s https://mirror.openshift.com/pub/openshift-v4/clients/ocp-dev-preview/latest/release.txt | grep 'Name:' | awk -F: '{print $2}' | xargs)
fi

# First try to find version in official mirror
RELEASE_IMAGE_SOURCE="https://mirror.openshift.com/pub/openshift-v4/clients/ocp-dev-preview"
RELEASE_IMAGE=$(curl -s $RELEASE_IMAGE_SOURCE/$VERSION/release.txt | grep 'Pull From: quay.io' | awk -F ' ' '{print $3}' | xargs)

if [[ -z "$RELEASE_IMAGE" ]]; then
    # Version not found in official mirror, so try CI repo
    RELEASE_IMAGE_SOURCE="https://openshift-release-artifacts.svc.ci.openshift.org"
    RELEASE_IMAGE=$(curl -s $RELEASE_IMAGE_SOURCE/$VERSION/release.txt | grep 'Pull From: registry' | awk -F ' ' '{print $3}' | xargs)
fi

if [[ -z "$RELEASE_IMAGE" ]]; then
    echo "Unable to find release image for version $VERSION!"
    exit 1;
fi

echo "Using version $VERSION from repo $RELEASE_IMAGE_SOURCE"

CMD=openshift-baremetal-install
PULL_SECRET=~/pull-secret.json
EXTRACT_DIR=$(pwd)

# Get the oc binary
curl $RELEASE_IMAGE_SOURCE/$VERSION/openshift-client-linux-$VERSION.tar.gz | tar zxvf - oc
sudo cp ./oc /usr/local/bin/oc
# Extract the baremetal installer
oc adm release extract --registry-config "${PULL_SECRET}" --command=$CMD --to "${EXTRACT_DIR}" ${RELEASE_IMAGE}

COMMIT_ID=$(./openshift-baremetal-install version | grep '^built from commit' | awk '{print $4}')

export RHCOS_URI=$(curl -s -S https://raw.githubusercontent.com/openshift/installer/$COMMIT_ID/data/data/rhcos.json | jq .images.openstack.path | sed 's/"//g')
export RHCOS_PATH=$(curl -s -S https://raw.githubusercontent.com/openshift/installer/$COMMIT_ID/data/data/rhcos.json | jq .baseURI | sed 's/"//g')

# Place the URL printed by the following command into your metal3-config.yaml
# as the "rhcos_image_url" value if necessary
IMAGE_URL="$RHCOS_PATH$RHCOS_URI"

if [[ -f "$HOME/metal3-config.yaml" ]]; then
    sed -i 's@rhcos_image_url.*@rhcos_image_url: '"$IMAGE_URL"'@' "$HOME/metal3-config.yaml"
    echo "$HOME/metal3-config.yaml \"rhcos_image_url\" updated!"
else
    printf "RHCOS IMAGE (place this in metal3-config.yaml as \"rhcos_image_url\"):\n $IMAGE_URL\n"
fi

# Set up the image cache to boost bootstrap performance
IMAGE_FILE=$(echo "$RHCOS_URI" | rev | cut -d '.' -f 2- | rev)
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
