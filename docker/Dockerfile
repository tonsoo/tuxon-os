FROM ubuntu:24.04

LABEL maintainer="alyssoncaoa@hotmail.com"
WORKDIR /tuxon-os

RUN apt update && apt install -y \
    debootstrap \
    grub-pc-bin \
    grub-efi-amd64-bin \
    xorriso \
    squashfs-tools \
    sudo \
    systemd \
    dosfstools \
    mtools \
    isolinux \
    curl \
    git \
    vim \
    bash \
    casper \
    initramfs-tools \
    linux-image-generic \
    && apt clean

RUN useradd -ms /bin/bash builder && echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER builder

CMD ["/bin/bash"]
