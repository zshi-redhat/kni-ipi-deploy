#!/bin/bash

CONTAINER_NAME="ipi-cordnds"
CLUSTER_DNS="192.168.111.3"
PROJECT_DIR="/root/kni-ipi-deploy"

podman run -d --expose=53/udp --name "$CONTAINER_NAME" \
            -p "$CLUSTER_DNS:53:53" -p "$CLUSTER_DNS:53:53/udp" \
            -v "$PROJECT_DIR/dns:/etc/coredns:z" coredns/coredns:latest \
            -conf /etc/coredns/Corefile
