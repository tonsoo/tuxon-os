#!/bin/bash

set -e

DOCKER_NAME="tuxon-os-instance"
LOCAL_BOOT_DIR="boot"

if ! command -v qemu-system-x86_64 &> /dev/null
then
    echo "To run this OS it's necessary to have qemu-system-x86_64 installed."
    read -p "Do you wish to install it? (yes/no): " choice
    case "$choice" in
        yes|Yes|Y|y )
            sudo apt install -y qemu-system-x86
            ;;
        * )
            echo "QEMU not installed. Exiting."
            exit 1
            ;;
    esac
fi

docker stop "$DOCKER_NAME" &> /dev/null || true
docker rm "$DOCKER_NAME" &> /dev/null || true

docker build -t tuxon-os/scratch-nogui -f Dockerfile.Nogui .
docker run -d --name "$DOCKER_NAME" tuxon-os/scratch-nogui

mkdir -p "$LOCAL_BOOT_DIR"

docker cp "$DOCKER_NAME":/distro/boot/boot "$LOCAL_BOOT_DIR/boot"

docker stop "$DOCKER_NAME"
docker rm "$DOCKER_NAME"

qemu-system-x86_64 -drive file=boot/boot,format=raw -nographic