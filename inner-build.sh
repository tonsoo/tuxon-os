#!/bin/bash
set -e

# Define KERNEL_VER globally so all child scripts can access it via environment
export KERNEL_VER=6.9

# Define the new ISO name
export ISO_NAME="tuxon-os.iso"

LOG_DIR="/build/output/logs" # This directory will be created within the mounted /output volume
CURRENT_TIMESTAMP=$(date +%Y%m%d-%H%M%S) # Get a unique timestamp for the log run

echo "--- Starting full TuxonOS build process ---"
echo "Log files for this run will be saved in: $LOG_DIR (on container), which maps to ./output/logs (on host)"
echo "Timestamp for this build: $CURRENT_TIMESTAMP"

mkdir -p "$LOG_DIR" # Ensure log directory exists

# Define log file paths with levels
SETUP_ROOTFS_CMD_LOG="$LOG_DIR/setup-rootfs-$CURRENT_TIMESTAMP.command.log"
SETUP_ROOTFS_STATUS_LOG="$LOG_DIR/setup-rootfs-$CURRENT_TIMESTAMP.status.log"

BUILD_KERNEL_CMD_LOG="$LOG_DIR/build-kernel-$CURRENT_TIMESTAMP.command.log"
BUILD_KERNEL_STATUS_LOG="$LOG_DIR/build-kernel-$CURRENT_TIMESTAMP.status.log"

BUILD_INITRD_CMD_LOG="$LOG_DIR/build-initrd-$CURRENT_TIMESTAMP.command.log"
BUILD_INITRD_STATUS_LOG="$LOG_DIR/build-initrd-$CURRENT_TIMESTAMP.status.log"

BUILD_ISO_CMD_LOG="$LOG_DIR/build-iso-$CURRENT_TIMESTAMP.command.log"
BUILD_ISO_STATUS_LOG="$LOG_DIR/build-iso-$CURRENT_TIMESTAMP.status.log"

# Function to log status messages
log_status() {
    echo "$(date +%H:%M:%S) - $1" | tee -a "$2"
}

# --- Setup RootFS ---
log_status "Starting scripts/setup-rootfs.sh..." "$SETUP_ROOTFS_STATUS_LOG"
scripts/setup-rootfs.sh > "$SETUP_ROOTFS_CMD_LOG" 2>&1
log_status "✅ RootFS setup completed. Check $SETUP_ROOTFS_CMD_LOG for command output." "$SETUP_ROOTFS_STATUS_LOG"

# --- Build Kernel ---
log_status "Starting kernel/build-kernel.sh..." "$BUILD_KERNEL_STATUS_LOG"
kernel/build-kernel.sh > "$BUILD_KERNEL_CMD_LOG" 2>&1
log_status "✅ Kernel build completed. Check $BUILD_KERNEL_CMD_LOG for command output." "$BUILD_KERNEL_STATUS_LOG"

# --- TEMPORARY AGGRESSIVE DEBUGGING: VERIFY MODULES IN ROOTFS DIRECTLY ---
# This part runs AFTER kernel/build-kernel.sh has completed
log_status "AGGRESSIVE DEBUG: Verifying kernel modules in /build/rootfs/lib/modules/ from host..." "$BUILD_KERNEL_STATUS_LOG"

# Get the Container ID of the current running build container
# This depends on the 'docker run' command in build.sh setting a name, or being the last running container.
# A more robust way would be to pass the CONTAINER_ID from build.sh into inner-build.sh.
# For now, let's assume `docker ps -lq` works as inner-build.sh runs inside the container itself.
# Corrected: inner-build.sh itself is running in the container. No need for docker exec.
# Just run ls -lR directly, as it is already in the correct context.

KERNEL_FULL_VER_DIAGNOSTIC=$(cat /build/linux-$KERNEL_VER/include/config/kernel.release)
if [ -z "$KERNEL_FULL_VER_DIAGNOSTIC" ]; then
    log_status "ERROR: Could not get KERNEL_FULL_VER for verification. Exiting." "$BUILD_KERNEL_STATUS_LOG"
    exit 1
fi

echo "--- Direct inspection of /build/rootfs/lib/modules/${KERNEL_FULL_VER_DIAGNOSTIC} (within current container) ---" | tee -a "$BUILD_KERNEL_STATUS_LOG"
# Perform the recursive listing directly.
# Output is redirected to the BUILD_KERNEL_STATUS_LOG (which is also tee'd to console).
ls -lR "/build/rootfs/lib/modules/${KERNEL_FULL_VER_DIAGNOSTIC}" | tee -a "$BUILD_KERNEL_STATUS_LOG"
echo "-------------------------------------------------------------------------------------------------------" | tee -a "$BUILD_KERNEL_STATUS_LOG"

log_status "AGGRESSIVE DEBUG: Module verification complete. Check output above for full listing." "$BUILD_KERNEL_STATUS_LOG"
# --- END AGGRESSIVE DEBUGGING ---


# --- Build Initrd ---
log_status "Starting scripts/build-initrd.sh..." "$BUILD_INITRD_STATUS_LOG"
scripts/build-initrd.sh > "$BUILD_INITRD_CMD_LOG" 2>&1
log_status "✅ Initrd build completed. Check $BUILD_INITRD_CMD_LOG for command output." "$BUILD_INITRD_STATUS_LOG"

# --- Build ISO ---
log_status "Starting scripts/build-iso.sh /build/$ISO_NAME..." "$BUILD_ISO_STATUS_LOG"
scripts/build-iso.sh "/build/$ISO_NAME" > "$BUILD_ISO_CMD_LOG" 2>&1
log_status "✅ ISO build completed. Check $BUILD_ISO_CMD_LOG for command output." "$BUILD_ISO_STATUS_LOG"

# --- Copy Final ISO ---
log_status "Finally copying the ISO to mounted output..." "$BUILD_ISO_STATUS_LOG"
cp "/build/$ISO_NAME" "/build/output/$ISO_NAME"
log_status "✅ ISO is in /build/output/$ISO_NAME (inside container) which is ./output/$ISO_NAME (on host)." "$BUILD_ISO_STATUS_LOG"

echo "--- Full build process finished ---"
echo "All logs available in: ./output/logs/ on your host machine."
echo "Final ISO: ./output/$ISO_NAME"