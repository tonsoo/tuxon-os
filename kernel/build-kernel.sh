#!/bin/bash

set -e

KERNEL_VER=6.9

wget -nc https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$KERNEL_VER.tar.xz
tar xf linux-$KERNEL_VER.tar.xz
cd linux-$KERNEL_VER

make defconfig
make -j$(nproc)

cp arch/x86/boot/bzImage /build/vmlinuz

echo "✅ Kernel built at /build/vmlinuz"
