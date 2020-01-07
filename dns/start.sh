#!/bin/bash

OUTPUT_DIR="generated"

CONTAINER_NAME="ipi-coredns"
PROJECT_DIR="$HOME/kni-ipi-deploy"

# shellcheck disable=SC1091
source "../settings.sh"

mkdir -p "$OUTPUT_DIR"

envsubst < Corefile.tmpl > "${OUTPUT_DIR}"/Corefile
# shellcheck disable=SC2016
envsubst '${CLUSTER_DOMAIN} ${CLUSTER_NAME}' < db.zone.tmpl > "${OUTPUT_DIR}"/db.zone
# shellcheck disable=SC2016
envsubst '${CLUSTER_DOMAIN} ${CLUSTER_NAME}' < db.reverse.tmpl > "${OUTPUT_DIR}"/db.reverse

podman run -d --expose=53/udp --name "$CONTAINER_NAME" \
            -p "$DNS_VIP:53:53/tcp" -p "$DNS_VIP:53:53/udp" \
            -v "$PROJECT_DIR/dns/$OUTPUT_DIR:/etc/coredns:z" coredns/coredns:latest \
            -conf /etc/coredns/Corefile
