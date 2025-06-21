#/bin/bash

# Display program version
version() {
    echo "$APP_NAME - ($VERSION)"
}



# Show padronized help message for a command
helpCommand() {
    echo "  $1            $2"
}



# Show help message
help() {
    echo "$APP_NAME"
    echo ""
    echo "$CMD [OPTIONS]"
    helpCommand "-h" "Prints this"
    helpCommand "-d" "Enabled debug mode on the script"
    helpCommand "-i <path>" "Specify the input Ubuntu ISO path"
    helpCommand "-o <path>" "Specify the output directory for the custom ISO"
    helpCommand "--chroot" "Enter the chroot environment for manual customization"
    helpCommand "--build" "Start the ISO build process"
}

# Log messages with a timestamp and step indication
log_step() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] STEP: $1"
}

# Check if a command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: Command '$1' not found. Please install it."
        exit 1
    fi
}

# Mount an ISO image
mount_iso() {
    local ISO_PATH="$1"
    local MOUNT_POINT="$2"
    log_step "Mounting ISO: $ISO_PATH to $MOUNT_POINT"
    sudo mkdir -p "$MOUNT_POINT" || { echo "Failed to create mount point $MOUNT_POINT"; exit 1; }
    sudo mount -o loop "$ISO_PATH" "$MOUNT_POINT" || { echo "Failed to mount ISO $ISO_PATH"; exit 1; }
}

# Unmount a directory
unmount_dir() {
    local DIR_PATH="$1"
    log_step "Unmounting: $DIR_PATH"
    sudo umount "$DIR_PATH" || { echo "Failed to unmount $DIR_PATH"; }
}

# Extract the squashfs filesystem
extract_squashfs() {
    local SQUASHFS_PATH="$1"
    local EXTRACT_POINT="$2"
    log_step "Extracting squashfs from $SQUASHFS_PATH to $EXTRACT_POINT"
    sudo mkdir -p "$EXTRACT_POINT" || { echo "Failed to create extract point $EXTRACT_POINT"; exit 1; }
    sudo unsquashfs -f -d "$EXTRACT_POINT" "$SQUASHFS_PATH" || { echo "Failed to extract squashfs"; exit 1; }
}

# Prepare for chroot
prepare_chroot() {
    local CHROOT_DIR="$1"
    log_step "Preparing chroot environment in $CHROOT_DIR"

    sudo mkdir -p "$CHROOT_DIR/dev"
    sudo mkdir -p "$CHROOT_DIR/proc"
    sudo mkdir -p "$CHROOT_DIR/sys"
    
    sudo mount --bind /dev "$CHROOT_DIR/dev" || { echo "Failed to bind /dev"; exit 1; }
    sudo mount --bind /proc "$CHROOT_DIR/proc" || { echo "Failed to bind /proc"; exit 1; }
    sudo mount --bind /sys "$CHROOT_DIR/sys" || { echo "Failed to bind /sys"; exit 1; }
    # Adicionar resolv.conf para acesso à internet dentro do chroot
    sudo cp /etc/resolv.conf "$CHROOT_DIR/etc/" || { echo "Failed to copy resolv.conf"; exit 1; }
}

# Clean chroot environment
clean_chroot() {
    local CHROOT_DIR="$1"
    log_step "Cleaning chroot environment in $CHROOT_DIR"
    sudo rm "$CHROOT_DIR/etc/resolv.conf" # Remover o resolv.conf copiado
    sudo umount -l "$CHROOT_DIR/dev" || { echo "Failed to unmount /dev in chroot"; }
    sudo umount -l "$CHROOT_DIR/proc" || { echo "Failed to unmount /proc in chroot"; }
    sudo umount -l "$CHROOT_DIR/sys" || { echo "Failed to unmount /sys in chroot"; }
}

# Enter the chroot environment
enter_chroot_manual() {
    local CHROOT_DIR="$1"
    log_step "Entering chroot environment at $CHROOT_DIR. Type 'exit' to leave."
    sudo chroot "$CHROOT_DIR" /bin/bash
    log_step "Exited chroot environment."
}


# Create new squashfs filesystem
create_squashfs_file() {
    local SOURCE_DIR="$1"
    local OUTPUT_FILE="$2"
    log_step "Creating new squashfs file from $SOURCE_DIR to $OUTPUT_FILE"
    sudo mksquashfs "$SOURCE_DIR" "$OUTPUT_FILE" -comp xz -b 1M -Xbcj x86 -e boot || { echo "Failed to create squashfs"; exit 1; }
}

# Create the final ISO image
create_iso_image() {
    local TEMP_DIR="$1"
    local OUTPUT_ISO="$2"
    local ISO_LABEL="$3" # Ex: "MyCustomUbuntu"
    log_step "Creating final ISO image: $OUTPUT_ISO with label $ISO_LABEL"

    # Assume that all necessary files are copied to the TEMP_DIR by the main script
    # For a bootable ISO, you often need to copy the boot files (casper, isolinux/grub, etc.)
    # from the original ISO.

    # This is a simplified call to genisoimage/xorriso. Real world might need more options.
    # Using xorriso is often preferred for modern Ubuntu ISOs.

    # Example using xorriso (more robust for Ubuntu ISOs)
    sudo xorriso -as mkisofs \
        -r -V "$ISO_LABEL" \
        -o "$OUTPUT_ISO" \
        -J -l -b isolinux/isolinux.bin \
        -c isolinux/boot.cat \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        "$TEMP_DIR" || { echo "Failed to create ISO image"; exit 1; }

    # Example using genisoimage (older, might not work as well for newer Ubuntus)
    # sudo genisoimage -r -V "$ISO_LABEL" \
    #     -cache-inodes -J -l \
    #     -b isolinux/isolinux.bin \
    #     -c isolinux/boot.cat \
    #     -no-emul-boot -boot-load-size 4 -boot-info-table \
    #     -o "$OUTPUT_ISO" \
    #     "$TEMP_DIR" || { echo "Failed to create ISO image"; exit 1; }
}

# Function to run commands inside chroot
run_in_chroot() {
    local CHROOT_DIR="$1"
    shift # Remove the first argument (CHROOT_DIR)
    local COMMAND="$@"
    sudo chroot "$CHROOT_DIR" /bin/bash -c "$COMMAND"
}
