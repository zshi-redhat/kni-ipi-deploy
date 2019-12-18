#!/bin/bash

OUTPUT_DIR="generated"

CONTAINER_NAME="ipi-dnsmasq-bm"
CLUSTER_DNS="192.168.111.3"
PROJECT_DIR="/root/kni-ipi-deploy"

ORIGIN='$ORIGIN'
source "../settings.sh"

mkdir -p "$OUTPUT_DIR"/bm/etc
mkdir -p "$OUTPUT_DIR"/bm/var
 
cat dnsmasq.conf.tmpl | envsubst > "${OUTPUT_DIR}"/bm/etc/dnsmasq.conf
cat dnsmasq.hostsfile.tmpl | envsubst > "${OUTPUT_DIR}"/bm/etc/dnsmasq.hostsfile

CONTAINER_NAME="ipi-dnsmasq-bm"
CONTAINER_IMAGE="quay.io/poseidon/dnsmasq"

podman run -d --name "$CONTAINER_NAME" --net=host \
            -v "$PROJECT_DIR/dhcp/bm/var/run:/var/run/dnsmasq:Z" \
            -v "$PROJECT_DIR/dhcp/bm/etc/dnsmasq.d:/etc/dnsmasq.d:Z" \
            --expose=53 --expose=53/udp --expose=67 --expose=67/udp --expose=69 \
            --expose=69/udp --cap-add=NET_ADMIN "$CONTAINER_IMAGE" \
            --conf-file=/etc/dnsmasq.d/dnsmasq.conf -u root -d -q
