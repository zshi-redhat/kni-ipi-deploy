#!/bin/bash

OUTPUT_DIR="generated"

CONTAINER_NAME="ipi-coredns"
PROJECT_DIR="/root/kni-ipi-deploy"

# shellcheck disable=SC1091
source "../settings.sh"

mkdir -p "$OUTPUT_DIR"
 
envsubst < db.zone > "${OUTPUT_DIR}"/db.zone
envsubst < db.reverse > "${OUTPUT_DIR}"/db.reverse

podman run -d --expose=53/udp --name "$CONTAINER_NAME" \
            -p "$DNS_VIP:53:53" -p "$CLUSTER_DNS:53:53/udp" \
            -v "$PROJECT_DIR/dns/$OUTPUT_DIR:/etc/coredns:z" coredns/coredns:latest \
            -conf /etc/coredns/Corefile
