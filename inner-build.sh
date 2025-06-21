#!/bin/bash
set -e

echo "Starting setup-rootfs.sh..."
scripts/setup-rootfs.sh
echo "✅ RootFS setup completed. Disk usage:"
du -sh /build/rootfs
df -h /build

echo "Starting kernel/build-kernel.sh..."
kernel/build-kernel.sh
echo "✅ Kernel build completed."

echo "Starting scripts/build-initrd.sh..."
scripts/build-initrd.sh
echo "✅ Initrd build completed."

echo "Starting scripts/build-iso.sh..."
scripts/build-iso.sh /build/my-linux-distro.iso
echo "✅ ISO build completed."

cp /build/my-linux-distro.iso /output/
echo "✅ ISO is in /output"