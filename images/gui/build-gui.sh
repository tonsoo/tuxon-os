#!/bin/bash

set -e

DOCKER_NAME="tuxon-os-instance-gui"
LOCAL_BOOT_DIR="boot-gui"

mkdir -p "$LOCAL_BOOT_DIR"

source ../ensure-qemu.sh

docker stop "$DOCKER_NAME" &> /dev/null || true
docker rm "$DOCKER_NAME" &> /dev/null || true

docker build -t tuxon-os/scratch-gui -f Dockerfile.Gui .
docker run --privileged \
    -v "$(pwd)/scripts:/build-scripts:ro" \
    -v "$(pwd)/$LOCAL_BOOT_DIR:/output:rw" \
    --name "$DOCKER_NAME" \
    tuxon-os/scratch-gui \
    bash /build-scripts/finish-build.sh

docker stop "$DOCKER_NAME"
docker rm "$DOCKER_NAME"

qemu-system-x86_64 "$LOCAL_BOOT_DIR/boot.img" -vga cirrus