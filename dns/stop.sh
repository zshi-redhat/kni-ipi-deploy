#!/bin/bash

CONTAINER_NAME="ipi-coredns"

podman stop "${CONTAINER_NAME}"
podman rm "${CONTAINER_NAME}"

