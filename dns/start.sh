#!/bin/bash

OUTPUT_DIR="generated"

CONTAINER_NAME="ipi-coredns"
CLUSTER_DNS="192.168.111.3"
PROJECT_DIR="/root/kni-ipi-deploy"

ORIGIN='$ORIGIN'
source "../settings.sh"

mkdir -p "$OUTPUT_DIR"
 
cat db.zone | envsubst > "${OUTPUT_DIR}"/db.zone
cat db.reverse | envsubst > "${OUTPUT_DIR}"/db.reverse

podman run -d --expose=53/udp --name "$CONTAINER_NAME" \
            -p "$CLUSTER_DNS:53:53" -p "$CLUSTER_DNS:53:53/udp" \
            -v "$PROJECT_DIR/dns/$OUTPUT_DIR:/etc/coredns:z" coredns/coredns:latest \
            -conf /etc/coredns/Corefile
