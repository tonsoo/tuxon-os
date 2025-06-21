#!/bin/bash
set -e

# Define KERNEL_VER.
# If KERNEL_VER is already set (e.g., exported from inner-build.sh), use that value.
# Otherwise, default to 6.9. This makes the script robust for direct execution.
KERNEL_VER=${KERNEL_VER:-6.9}

# Get the precise kernel version including local version if any
# This path is relative to the current working directory inside the container (linux-$KERNEL_VER)
KERNEL_FULL_VER=$(cat linux-$KERNEL_VER/include/config/kernel.release)


# Fetch and unpack kernel source
wget -nc https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$KERNEL_VER.tar.xz
tar xf linux-$KERNEL_VER.tar.xz
cd linux-$KERNEL_VER

# Build
make defconfig
make -j$(nproc) # This command builds the kernel and its modules

# --- DIAGNOSTIC: Check compiled modules in the kernel source tree ---
echo "--- DIAGNOSTIC: Contents of compiled modules in source tree (./lib/modules/${KERNEL_FULL_VER}): ---"
# Check the top-level module directory in the source tree
ls -lh ./lib/modules/${KERNEL_FULL_VER}/ || true
# Check a specific expected subdirectory (e.g., block drivers)
ls -lh ./lib/modules/${KERNEL_FULL_VER}/kernel/drivers/block/ || true
# Check for a specific module file (e.g., virtio_blk.ko, a common virtio driver)
ls -lh ./lib/modules/${KERNEL_FULL_VER}/kernel/drivers/block/virtio_blk.ko || true
echo "---------------------------------------------------------------------"
# --- END DIAGNOSTIC ---


# Ensure modules preparation is complete
make modules_prepare

echo "--- Preparing module installation directory ---"
# Explicitly create the target directory for modules within the rootfs
# This ensures it exists and is ready for 'make modules_install'
chroot /build/rootfs /bin/bash -c "mkdir -p /lib/modules/${KERNEL_FULL_VER}/"
chroot /build/rootfs /bin/bash -c "chmod 755 /lib/modules/${KERNEL_FULL_VER}/"
# Also ensure the target directory for headers symlink is correct
chroot /build/rootfs /bin/bash -c "mkdir -p /usr/src"


echo "--- Installing kernel modules to /build/rootfs ---"
make modules_install INSTALL_MOD_PATH=/build/rootfs

# --- DIAGNOSTIC: Check installed modules in the target rootfs ---
echo "--- DIAGNOSTIC: Contents of installed modules in /build/rootfs/lib/modules/${KERNEL_FULL_VER}: ---"
# The 'ls' needs to run inside the chroot to see the actual contents after installation
docker run --rm tuxon-os ls -lh /build/rootfs/lib/modules/${KERNEL_FULL_VER}/ || true
docker run --rm tuxon-os ls -lh /build/rootfs/lib/modules/${KERNEL_FULL_VER}/kernel/drivers/block/ || true
docker run --rm tuxon-os ls -lh /build/rootfs/lib/modules/${KERNEL_FULL_VER}/kernel/drivers/block/virtio_blk.ko || true
echo "-------------------------------------------------------------------"
# --- END DIAGNOSTIC ---


echo "--- Installing kernel headers to /build/rootfs ---"
make headers_install INSTALL_HDR_PATH=/build/rootfs/usr

# Copy the built bzImage to /build as vmlinuz
cp arch/x86/boot/bzImage /build/vmlinuz

echo "✅ Kernel built, modules, and headers installed to /build/rootfs"
echo "   Kernel bzImage copied to /build/vmlinuz"