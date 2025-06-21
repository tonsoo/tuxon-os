#!/bin/bash
set -e

# Define KERNEL_VER.
# If KERNEL_VER is already set (e.g., exported from inner-build.sh), use that value.
# Otherwise, default to 6.9. This makes the script robust for direct execution.
KERNEL_VER=${KERNEL_VER:-6.9}

echo "Starting initrd build using update-initramfs..."

# --- Ensure pseudo-filesystems are in a clean state before mounting ---
echo "Attempting to unmount previous pseudo-filesystems..."
umount -lf /build/rootfs/dev || true
umount -lf /build/rootfs/sys || true
umount -lf /build/rootfs/proc || true
echo "Previous pseudo-filesystems unmounted (if they were mounted)."

# --- Mount necessary pseudo-filesystems for chroot ---
echo "Mounting /proc in chroot..."
if ! mountpoint -q /build/rootfs/proc; then
    mount -t proc proc /build/rootfs/proc
else
    echo "/proc already mounted in chroot. Skipping."
fi

echo "Mounting /sys in chroot..."
if ! mountpoint -q /build/rootfs/sys; then
    mount -t sysfs sys /build/rootfs/sys
else
    echo "/sys already mounted in chroot. Skipping."
fi

echo "Mounting /dev in chroot..."
if ! mountpoint -q /build/rootfs/dev; then
    mount --bind /dev /build/rootfs/dev
else
    echo "/dev already mounted in chroot. Skipping."
fi

# Derive KERNEL_FULL_VER
KERNEL_FULL_VER=$(cat /build/linux-$KERNEL_VER/include/config/kernel.release)

# Ensure /boot directory exists in the chroot environment
chroot /build/rootfs mkdir -p /boot

# --- Configure initramfs-tools for GZIP and ALL modules ---
echo "Configuring initramfs-tools to use GZIP compression and force all modules..."
chroot /build/rootfs /bin/bash -c "echo 'COMPRESS=gzip' > /etc/initramfs-tools/initramfs.conf"
# This line forces update-initramfs to include ALL available modules
chroot /build/rootfs /bin/bash -c "mkdir -p /etc/initramfs-tools/conf.d && echo 'MODULES=all' > /etc/initramfs-tools/conf.d/force_all_modules.conf"


# Create a symlink to the kernel build directory inside the chroot's /lib/modules/<version>/build
echo "Creating kernel build symlink in chroot for update-initramfs..."
chroot /build/rootfs /bin/bash -c "mkdir -p /lib/modules/${KERNEL_FULL_VER}/"
chroot /build/rootfs /bin/bash -c "ln -sf /build/linux-${KERNEL_VER} /lib/modules/${KERNEL_FULL_VER}/build"


echo "Generating initramfs for kernel version: ${KERNEL_FULL_VER}"

# --- DIAGNOSTIC: Check module dir *from within the chroot* immediately before update-initramfs ---
echo "--- DIAGNOSTIC (inside chroot): Contents of /lib/modules/${KERNEL_FULL_VER} before update-initramfs ---"
chroot /build/rootfs /bin/bash -c "ls -lh /lib/modules/${KERNEL_FULL_VER}/" > /build/output/logs/chroot_modules_pre_update_initramfs-${CURRENT_TIMESTAMP}.log 2>&1
chroot /build/rootfs /bin/bash -c "ls -lh /lib/modules/${KERNEL_FULL_VER}/kernel/drivers/block/" >> /build/output/logs/chroot_modules_pre_update_initramfs-${CURRENT_TIMESTAMP}.log 2>&1 || true
echo "---------------------------------------------------------------------------------------------------"

# Run update-initramfs inside the chroot with verbose output
chroot /build/rootfs /bin/bash -c "update-initramfs -c -k ${KERNEL_FULL_VER} -v"

# --- DIAGNOSTIC: Check generated initramfs content inside chroot ---
echo "--- DIAGNOSTIC (inside chroot): Contents of generated initramfs before copy ---"
chroot /build/rootfs /bin/bash -c "ls -lh /boot/initrd.img-${KERNEL_FULL_VER}" > /build/output/logs/chroot_initrd_size_post_update_initramfs-${CURRENT_TIMESTAMP}.log 2>&1
chroot /build/rootfs /bin/bash -c "file /boot/initrd.img-${KERNEL_FULL_VER}" >> /build/output/logs/chroot_initrd_size_post_update_initramfs-${CURRENT_TIMESTAMP}.log 2>&1
echo "--------------------------------------------------------------------------------"


# Check for success of update-initramfs
if [ $? -ne 0 ]; then
  echo "❌ update-initramfs failed inside chroot! Check build-initrd.log for details."
  exit 1
fi

# Copy the generated initrd.img from its default location
cp "/build/rootfs/boot/initrd.img-${KERNEL_FULL_VER}" /build/initrd.img

# --- Final Unmount of pseudo-filesystems ---
echo "Unmounting pseudo-filesystems from chroot..."
umount -lf /build/rootfs/dev || true
umount -lf /build/rootfs/sys || true
umount -lf /build/rootfs/proc || true
echo "Pseudo-filesystems unmounted."

echo "✅ Initrd built at /build/initrd.img"
ls -lh /build/initrd.img
file /build/initrd.img