FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. Base tools for chroot + ISO
# Added 'squashfs-tools' for mksquashfs, 'xorriso' for ISO creation,
# 'grub-efi-amd64-bin' for UEFI grub, 'grub-pc-bin' for BIOS grub.
# 'isolinux' is crucial for the initial bootloader for BIOS systems.
RUN apt-get update && apt-get install -y \
    debootstrap xorriso grub-pc-bin grub-efi-amd64-bin mtools squashfs-tools isolinux \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Copy branding, scripts, and packages list
COPY scripts/ /scripts/
COPY branding/ /branding/
COPY packages.txt /packages.txt

# 3. Create chroot using Ubuntu Noble
RUN debootstrap --arch=amd64 noble /chroot http://archive.ubuntu.com/ubuntu

# 4. Enable universe/multiverse repos inside chroot
RUN echo "deb http://archive.ubuntu.com/ubuntu noble main universe multiverse" > /chroot/etc/apt/sources.list && \
    echo "deb http://archive.ubuntu.com/ubuntu noble-updates main universe multiverse" >> /chroot/etc/apt/sources.list && \
    echo "deb http://archive.ubuntu.com/ubuntu noble-security main universe multiverse" >> /chroot/etc/apt/sources.list

# 5. Install live-boot components and extras in chroot
# Removed the conflicting grub-pc and grub-efi-amd64 from the chroot installation.
RUN chroot /chroot apt-get update && chroot /chroot apt-get install -y --no-install-recommends \
    casper discover initramfs-tools linux-image-generic systemd-sysv live-boot live-config \
    # Added xserver-xorg-core and fonts-ubuntu for basic display functionality
    xserver-xorg-core fonts-ubuntu \
    && chroot /chroot apt-get clean && rm -rf /chroot/var/lib/apt/lists/*

# Install packages from packages.txt
# Ensure the desktop environment (e.g., ubuntu-desktop) is in packages.txt
# And that packages.txt is actually processed.
RUN chroot /chroot apt-get update && chroot /chroot apt-get install -y --no-install-recommends $(cat /packages.txt) \
    && chroot /chroot apt-get clean && rm -rf /chroot/var/lib/apt/lists/*

# 6. Branding and scripts
RUN cp -r /scripts/* /chroot/bin/ && \
    find /chroot/bin -maxdepth 1 -type f -exec chmod +x {} \; && \
    mkdir -p /chroot/usr/share/plymouth/themes/tuxonos-theme /chroot/usr/share/backgrounds && \
    cp /branding/logo.png /chroot/usr/share/plymouth/themes/tuxonos-theme/logo.png && \
    cp /branding/wallpaper.png /chroot/usr/share/backgrounds/default-wallpaper.png && \
    mkdir -p /chroot/etc/plymouth && \
    echo "set default tuxonos-theme" > /chroot/etc/alternatives/plymouth-theme && \
    ln -sf /etc/alternatives/plymouth-theme /chroot/etc/plymouth/plymouthd.conf && \
    \
    # --- Start comprehensive branding changes --- \
    sed -i "s/Ubuntu/TuxonOS/g" /chroot/etc/os-release && \
    sed -i "s/Ubuntu/TuxonOS/g" /chroot/etc/issue && \
    sed -i "s/Ubuntu/TuxonOS/g" /chroot/etc/issue.net && \
    find /chroot/etc/update-motd.d/ -type f -exec sed -i "s/Ubuntu/TuxonOS/g" {} + && \
    \
    # Change default hostname
    echo "tuxonos" > /chroot/etc/hostname && \
    \
    # Modify casper.conf for default live user (often 'ubuntu') and name
    # Ensure casper.conf exists before modifying
    [ -f /chroot/etc/casper.conf ] || echo "CASPER_DEFAULTS=quiet splash fsck" > /chroot/etc/casper.conf && \
    sed -i 's/LIVE_USER_NAME=.*/LIVE_USER_NAME="tuxonos"/g' /chroot/etc/casper.conf && \
    sed -i 's/LIVE_SYSTEM_NAME=.*/LIVE_SYSTEM_NAME="TuxonOS"/g' /chroot/etc/casper.conf && \
    \
    # Attempt to change in /etc/lsb-release if it exists (some systems still use it)
    if [ -f /chroot/etc/lsb-release ]; then \
        sed -i 's/^DISTRIB_ID=Ubuntu/DISTRIB_ID=TuxonOS/g' /chroot/etc/lsb-release; \
        sed -i 's/^DISTRIB_DESCRIPTION="Ubuntu .*/DISTRIB_DESCRIPTION="TuxonOS 24.04 LTS"/g' /chroot/etc/lsb-release; \
    fi && \
    \
    # Attempt to change common occurrences in profile files for the default user
    # This might require knowing the default user's home directory.
    # For a live system, the 'ubuntu' user's home is often created at boot.
    # For now, let's target /etc/skel (template for new users) if it applies.
    # Note: This is less reliable for the initial live user unless casper uses /etc/skel directly for user setup.
    sed -i 's/ubuntu@ubuntu/tuxonos@tuxonos/g' /chroot/etc/skel/.bashrc 2>/dev/null || true && \
    sed -i 's/ubuntu@ubuntu/tuxonos@tuxonos/g' /chroot/etc/skel/.profile 2>/dev/null || true
    # --- End comprehensive branding changes ---

# 7. Include casper in initramfs and update initramfs
RUN echo "casper" >> /chroot/etc/initramfs-tools/modules && \
    # Force update initramfs to include casper
    chroot /chroot update-initramfs -u -k all

# Get the kernel version for direct copying
RUN export KERNEL_VERSION=$(ls /chroot/boot/vmlinuz-* | head -n 1 | sed "s/.*vmlinuz-\(.*\)/\1/") && \
    echo "Detected Kernel Version: $KERNEL_VERSION" && \
    echo "export KERNEL_VERSION=$KERNEL_VERSION" >> /root/.bashrc

# 8. Make squashfs
RUN mksquashfs /chroot filesystem.squashfs -e boot

# 9. Prepare image structure for ISO
RUN mkdir -p image/casper image/boot/grub image/isolinux image/boot/grub/efi.img

# Copy kernel and initrd explicitly using the detected version
RUN export KERNEL_VERSION=$(ls /chroot/boot/vmlinuz-* | head -n 1 | sed "s/.*vmlinuz-\(.*\)/\1/") && \
    cp filesystem.squashfs image/casper/ && \
    cp /chroot/boot/vmlinuz-$KERNEL_VERSION image/casper/vmlinuz && \
    cp /chroot/boot/initrd.img-$KERNEL_VERSION image/casper/initrd

# 10. GRUB and ISOLINUX setup
# Copy standard isolinux files, including ldlinux.c32, libcom32.c32, and libutil.c32
RUN cp /usr/lib/ISOLINUX/isolinux.bin image/isolinux/ && \
    cp /usr/lib/syslinux/modules/bios/vesamenu.c32 image/isolinux/ && \
    cp /usr/lib/syslinux/modules/bios/ldlinux.c32 image/isolinux/ && \
    cp /usr/lib/syslinux/modules/bios/libcom32.c32 image/isolinux/ && \
    cp /usr/lib/syslinux/modules/bios/libutil.c32 image/isolinux/ # <--- ADD THIS LINE

# Create isolinux.cfg
RUN echo "DEFAULT vesamenu.c32\nTIMEOUT 300\nMENU TITLE TuxonOS Live\n\nLABEL live\n  MENU LABEL ^Live TuxonOS\n  LINUX /casper/vmlinuz\n  INITRD /casper/initrd\n  APPEND boot=casper quiet splash ---" > image/isolinux/isolinux.cfg && \
    cp image/isolinux/isolinux.cfg image/isolinux/syslinux.cfg

# Prepare GRUB for BIOS (for grub-mkrescue)
RUN mkdir -p image/boot/grub/ && \
    grub-mkimage -o image/boot/grub/boot.img -O i386-pc -p /boot/grub biosdisk part_msdos fat ext2 linux normal loopback configfile boot && \
    cp -r /usr/lib/grub/i386-pc image/boot/grub/

# Create grub.cfg for the ISO
RUN echo "set default=0\nset timeout=5\n\nmenuentry \"Live TuxonOS\" {\n  linux /casper/vmlinuz boot=casper quiet splash ---\n  initrd /casper/initrd\n}" > image/boot/grub/grub.cfg

# Prepare GRUB for EFI (for grub-mkrescue)
RUN mkdir -p image/EFI/BOOT && \
    grub-mkimage -o image/EFI/BOOT/bootx64.efi -O x86_64-efi -p /EFI/BOOT linux normal boot configfile && \
    cp -r /usr/lib/grub/x86_64-efi image/EFI/BOOT/

# 11. Build ISO using xorriso for hybrid boot (BIOS and UEFI)
# Using -as mkisofs to emulate mkisofs behavior which grub-mkrescue also does,
# but gives more control for hybrid ISOs.
RUN xorriso -as mkisofs \
    -r -V "TuxonOS" \
    -o /TuxonOS.iso \
    -J -R \
    -b isolinux/isolinux.bin \
    -c isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -eltorito-alt-boot \
    -e EFI/BOOT/bootx64.efi \
    -no-emul-boot -isohybrid-gpt-basdat \
    -isohybrid-apm-hfsplus \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    image/

# 12. Output
VOLUME /output
CMD cp /TuxonOS.iso /output/