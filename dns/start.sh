#!/bin/bash

OUTPUT_DIR="generated"

CONTAINER_NAME="ipi-coredns"
PROJECT_DIR="$HOME/kni-ipi-deploy"

# shellcheck disable=SC1091
source "../settings.sh"

export API_OCTET=$(echo "$API_VIP" | cut -d '.' -f 4)
export DNS_OCTET=$(echo "$DNS_VIP" | cut -d '.' -f 4)

mkdir -p "$OUTPUT_DIR"

envsubst < Corefile.tmpl > "${OUTPUT_DIR}"/Corefile
# shellcheck disable=SC2016
envsubst '${CLUSTER_DOMAIN} ${CLUSTER_NAME} ${API_VIP} ${DNS_VIP} ${INGRESS_VIP}' < db.zone.tmpl > "${OUTPUT_DIR}"/db.zone
# shellcheck disable=SC2016
envsubst '${CLUSTER_DOMAIN} ${CLUSTER_NAME} ${API_OCTET} ${DNS_OCTET}' < db.reverse.tmpl > "${OUTPUT_DIR}"/db.reverse

podman run -d --expose=53/udp --name "$CONTAINER_NAME" \
            -p "$DNS_IP:53:53/tcp" -p "$DNS_IP:53:53/udp" \
            -v "$PROJECT_DIR/dns/$OUTPUT_DIR:/etc/coredns:z" coredns/coredns:latest \
            -conf /etc/coredns/Corefile
