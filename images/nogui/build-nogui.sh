#!/bin/bash

set -e

DOCKER_NAME="tuxon-os-instance-nogui"
LOCAL_BOOT_DIR="boot-nogui"

mkdir -p "$LOCAL_BOOT_DIR"

source ../ensure-qemu.sh

docker stop "$DOCKER_NAME" &> /dev/null || true
docker rm "$DOCKER_NAME" &> /dev/null || true

docker build -t tuxon-os/scratch-nogui -f Dockerfile.Nogui .
docker run --privileged \
    -v "$(pwd)/scripts:/build-scripts:ro" \
    -v "$(pwd)/$LOCAL_BOOT_DIR:/output:rw" \
    --name "$DOCKER_NAME" \
    tuxon-os/scratch-nogui \
    bash /build-scripts/finish-build.sh

docker stop "$DOCKER_NAME"
docker rm "$DOCKER_NAME"

qemu-system-x86_64 -drive file="$LOCAL_BOOT_DIR/boot",format=raw -nographic