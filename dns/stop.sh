#!/bin/bash

CONTAINER_NAME="ipi-coredns"

sudo podman stop "${CONTAINER_NAME}"
sudo podman rm "${CONTAINER_NAME}"

