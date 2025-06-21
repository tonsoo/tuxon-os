#!/bin/bash
set -e

# --- Configuration ---
ISO_PATH="./output/tuxon-os.iso"
ISO_MOUNT_POINT="/tmp/iso_extract_$(date +%Y%m%d%H%M%S)" # Unique mount point
INITRD_EXTRACT_POINT="/tmp/initrd_contents_check_$(date +%Y%m%d%H%M%S)" # Unique extract point

echo "--- Starting ISO and Initrd Inspection ---"

# Ensure we are in the project's root directory
cd "$(git rev-parse --show-toplevel)"
echo "Current working directory: $(pwd)"

# Check if ISO file exists
if [ ! -f "$ISO_PATH" ]; then
    echo "ERROR: ISO file not found at $ISO_PATH. Please run build.sh first."
    exit 1
fi

# Create temporary directories
mkdir -p "$ISO_MOUNT_POINT"
mkdir -p "$INITRD_EXTRACT_POINT"

echo "Attempting to mount ISO: $ISO_PATH to $ISO_MOUNT_POINT"
sudo mount -o loop "$ISO_PATH" "$ISO_MOUNT_POINT"
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to mount ISO at $ISO_PATH. Check if file is corrupted or if you have loop device permissions."
    # Clean up what we can
    rmdir "$ISO_MOUNT_POINT" || true
    rmdir "$INITRD_EXTRACT_POINT" || true
    exit 1
fi
echo "ISO mounted successfully."

echo "--- Contents of the ISO's /boot directory: ---"
ls -lh "$ISO_MOUNT_POINT/boot/"

echo "--- Details of vmlinuz in ISO: ---"
file "$ISO_MOUNT_POINT/boot/vmlinuz"

echo "--- Details of initrd.img in ISO: ---"
file "$ISO_MOUNT_POINT/boot/initrd.img"

echo "--- Size of initrd.img in ISO: ---"
ls -lh "$ISO_MOUNT_POINT/boot/initrd.img"

echo "--- Contents of grub.cfg in ISO: ---"
cat "$ISO_MOUNT_POINT/boot/grub/grub.cfg"

echo ""
echo "--- Extracting and inspecting Initrd contents: ---"
cd "$INITRD_EXTRACT_POINT"

# Try to gunzip and cpio
if gunzip < "$ISO_MOUNT_POINT/boot/initrd.img" | cpio -idmv; then
    echo "Initrd extracted successfully."
else
    echo "WARNING: Failed to extract initrd as gzipped cpio. Trying uncompressed cpio..."
    # If gzip fails, try uncompressed cpio directly (less common but good fallback)
    if cpio -idmv < "$ISO_MOUNT_POINT/boot/initrd.img"; then
        echo "Initrd extracted successfully as uncompressed cpio."
    else
        echo "ERROR: Failed to extract initrd contents. It might be corrupted or in an unexpected format."
        cd "$(git rev-parse --show-toplevel)" # Go back to root before cleanup
        sudo umount "$ISO_MOUNT_POINT" || true
        rm -rf "$ISO_MOUNT_POINT" || true
        rm -rf "$INITRD_EXTRACT_POINT" || true
        exit 1
    fi
fi

echo "--- Top-level contents of initrd: ---"
ls -l

echo "--- Binaries in initrd: ---"
ls -l bin sbin usr/bin usr/sbin

echo "--- Contents of initrd's /lib/modules: ---"
ls -l lib/modules/

# Get the actual kernel version from the extracted initrd
KERNEL_VERSION_IN_INITRD=$(ls lib/modules/ 2>/dev/null | head -n 1) # Use 2>/dev/null to suppress error if dir empty
if [ -d "lib/modules/${KERNEL_VERSION_IN_INITRD}" ]; then
    echo "--- Kernel modules for ${KERNEL_VERSION_IN_INITRD}: ---"
    ls -l lib/modules/${KERNEL_VERSION_IN_INITRD}/kernel/drivers/block/
    ls -l lib/modules/${KERNEL_VERSION_IN_INITRD}/kernel/fs/ext4/ # Or whatever filesystem you are using
    # Look for virtio_blk.ko, ata_piix.ko, sd_mod.ko, ext4.ko etc.
else
    echo "ERROR: Kernel module directory not found in initrd at lib/modules/${KERNEL_VERSION_IN_INITRD}"
fi

# --- Clean up ---
echo ""
echo "--- Cleaning up temporary directories ---"
cd "$(git rev-parse --show-toplevel)" # Go back to repo root
sudo umount "$ISO_MOUNT_POINT"
rm -rf "$ISO_MOUNT_POINT"
rm -rf "$INITRD_EXTRACT_POINT"

echo "✅ ISO and Initrd inspection complete."