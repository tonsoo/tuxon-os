FROM ubuntu:22.04

RUN apt update && apt install -y \
    debootstrap \
    grub-pc-bin \
    grub-pc \
    grub-efi-amd64-bin \
    xorriso \
    squashfs-tools \
    systemd-sysv \
    sudo \
    curl \
    rsync \
    dosfstools \
    mtools \
    isolinux \
    syslinux-common \
    genisoimage \
    make \
    tar

# Work directory
WORKDIR /opt/tuxon-os

# Copy build script
COPY ../build.sh ./build.sh
RUN chmod +x ./build.sh

CMD ["/bin/bash"]
