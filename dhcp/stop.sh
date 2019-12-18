#!/bin/bash

PROJECT_DIR="/root/kni-ipi-deploy"
CONTAINER_NAME="ipi-dnsmasq-bm"

podman stop ipi-dnsmasq-bm
podman rm ipi-dnsmasq-bm

