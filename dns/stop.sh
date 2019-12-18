#!/bin/bash

PROJECT_DIR="/root/kni-ipi-deploy"
CONTAINER_NAME="ipi-coredns"

podman stop "${CONTAINER_NAME}"
podman rm "${CONTAINER_NAME}"

